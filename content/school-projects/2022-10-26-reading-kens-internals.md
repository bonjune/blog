---
title: KENS 내부 들여다보기
date: 2022-10-26T12:56:00+09:00
---

2022년 가을학기 전산망 개론에서 KENS 프로젝트를 통해
TCP/IP의 3-Way Handshaking과 Reliable Data Transfer를 구현하였다.

교수님의 판단으로 Flow Control은 스킵.

KENS는 꽤 신기한 프로그램이다.
교육용으로 설계되어 deterministic하게 동작한다.
내 생각에 실제 네트워크 노드들을 실행시켜 테스트하면
OS 등 여러 비결정적 요소들 때문에
절대로 deterministic하게 작동할 수 없는데,
KENS에서는 그런 일이 일어나지 않는다.

그래서 과제가 끝나고 숨돌릴 시간이 있을 무렵
KENS의 내부 구조를 들여다보았다.

## KENS 내부 구조

### `System`'s Properties

`System`은 KENS에서 네트워크를 구성하는 중요한 클래스다.
아래 코드에서 `System`이 관리하는 데이터들을 살펴보자.

``` cpp
private:
  std::unordered_set<std::shared_ptr<Runnable>> runnableReady;
  // ...
protected:
  // ...
  std::unordered_map<ModuleID, std::shared_ptr<Module>> registeredModule;

private:
  std::priority_queue<TimerContainer, std::vector<TimerContainer>,
                      TimerContainerLess>
      timerQueue;
  std::unordered_map<UUID, TimerContainer> activeTimer;
  std::unordered_set<UUID> activeUUID;
```

`System`은 `Runnable`, `Module`, `TimerContainer`를 관리하고 있다.
일단 이름을 통해 유추해보면 `Runnable` 실행가능한 함수 또는 프로그램일 것이다.
조금 더 들여다보자.

### `Runnable`

``` cpp
class Runnable {
protected:
  // ...
  virtual void main() = 0; // main program logic
  virtual void run() final;

public:
  enum class State {
    CREATED,
    STARTING,
    READY,
    RUNNING,
    WAITING,
    TERMINATED,
  };
  
  virtual void start() final;
  virtual State wake() final;
  virtual void ready() final;
  friend class System;

private:
  State state;
  std::mutex stateMtx;
  std::unique_lock<std::mutex> threadLock; //  for thread
  std::unique_lock<std::mutex> schedLock;  //  for scheduler
  std::condition_variable cond;
  std::thread thread;
}
```

첫번째 과제였던 `EchoAssignment` 클래스가 `Runnable` 클래스를 상속하고 있다.
아하! `Runnable`은 실행가능한 프로그램을 의미하는 것 같다.

`Runnable`을 상속하는 클래스는 `main` 메소드를 구현해 프로그램의 메인 로직을 정의하고,
`Runnable` 인스턴스는 실행, 대기, 종료 등 상태를 가진다.

KENS 스케쥴러에 의해 상태 전환이 일어나고, `mutex`, `condvar` 를 이용해 실행이 제어된다.

`Runnable`의 사용예제를 보자.

``` cpp
void SystemCallApplication::initialize() { start(); }

int SystemCallApplication::E_Syscall(
    const SystemCallInterface::SystemCallParameter &param) {
  if (!this->host.isRunning())
    return -1;

  syscallRet = -1;
  host.issueSystemCall(pid, param);
  wait();
  return syscallRet;
}

void SystemCallApplication::returnSyscall(int retVal) {
  syscallRet = retVal;
  ready();
}
```

`SystemCallApplication` 클래스는 `Runnable`을 상속한다.
`initialize()`가 `start()`를, `E_Syscall`이 `wait()`를, `returnSyscall()`이 `ready()`를 각각 호출하는 것을 볼 수 있다.
`E_Syscall()`과 `returnSyscall()`은 `Runnable`이 제공하는 상태 제어 기능을 이용해
시스템콜의 blocking behavior를 구현한다.
실제 커널 시스템콜과 같이 시스템콜이 반환하기 전까지
유저 프로그램이 실행되지 않는 것을 표현하는 것이다.

`E_Syscall()`을 통해 `wait()` 가 호출되면
`Runnable` 인스턴스의 실행이 중단되고,
`System`의 `run()`을 통해 어떤 인스턴스가 다음에 실행될지 결정된다!

이는 협동 스케쥴링(Cooperative Scheduling)에서
쓰레드(혹은 태스크)가 양보(yield)하는 것을 의미한다.

### `Module`

``` cpp
class Module {
private:
  System &system;
  ModuleID id;
  // ...
}
```

`Module`은 `System`에/으로부터 `Message`를 송수신할 수 있는 인터페이스다.

다음 콜백이 정의되어 있다.

1. `Message`가 목적지 모듈에 도착했을 때
2. 목적지 모듈에서 처리가 끝났을 때
3. 처리가 되기 전에 취소되었을 때

### `Message`

``` cpp
class MessageBase {
public:
  MessageBase() {}
  virtual ~MessageBase() {}
};

class EmptyMessage : public MessageBase {
public:
  static EmptyMessage &shared();
  bool operator==(const EmptyMessage &b) const { return true; }
};

using Message = std::unique_ptr<MessageBase>;
```

`Message`는 그냥 타입 지정을 위한 빈(empty) 클래스다.


### `TimerContainer`

``` cpp
class TimerContainerInner {
public:
  const ModuleID from;
  const ModuleID to;
  bool canceled;
  Time wakeup;
  Module::Message message;
  UUID uuid;
  TimerContainerInner(const ModuleID from, const ModuleID to, bool canceled,
                      Time wakeup, Module::Message message, UUID uuid)
      : from(from), to(to), canceled(canceled), wakeup(wakeup),
        message(std::move(message)), uuid(uuid) {}
};

  using TimerContainer = std::shared_ptr<TimerContainerInner>;
```

`TimerContainer`는 `System`의 내부 클래스로 정의되어 있다.
메시지의 출발지/도착지, 시간정보가 담겨져있다.

`TimerContainerLess`라는 클래스도 정의되어 있는데, 위에서 보았듯이 `System`에서 `timerQueue`의 우선순위를 정하기 위해 사용한다.
`wakeup`의 값이 큰 순서대로 `pop`되도록 지정된 것 같다. (확실하지 않다는 이야기, 하지만 보통 less로 비교가 이뤄지면 높은 값부터 pop한다.)

### `System`'s `run` method

``` cpp
void System::run(Time till) {
    // ...
    while (true) {
      while (!runnableReady.empty()) {
        for (auto r = runnableReady.begin(); r != runnableReady.end();) {
          auto next = (*r)->wake();
          if (next != Runnable::State::READY) {
            r = runnableReady.erase(r);
          } else {
            ++r;
          }
        }
      }
    // ...
    if (till != 0 && timerQueue.top()->wakeup > till)
      break;

    TimerContainer current = timerQueue.top();
    assert(current);
    timerQueue.pop();
    // ...
    this->currentTime = current->wakeup;
    // for(TimerContainer* container : sameTime)
    {
      TimerContainer container = std::move(current);
      if (!container->canceled) {
        // invoke `messageReceived` at `to` Module
        Module::Message ret = registeredModule[container->to]->messageReceived(
            container->from, *container->message);

        // invoke `messageFinished` at `from` Module
        registeredModule[container->from]->messageFinished(
            container->to, std::move(container->message),
            ret != nullptr ? *ret : Module::EmptyMessage::shared());

        // Also, if there is a feedback from the receiver,
        // invoke `messageFinished` callback on the sender side
        if (ret != nullptr)
          registeredModule[container->to]->messageFinished(
              container->to, std::move(ret), Module::EmptyMessage::shared());
      } else {
        registeredModule[container->from]->messageCancelled(
            container->to, std::move(container->message));
      }

      // We are now done with current timer container
      this->activeTimer.erase(container->uuid);
      this->activeUUID.erase(container->uuid);
      assert(container.use_count() == 1);
    }
  }
}
```

`System`의 메인 루프다.
각 루프마다 `runnableReady`에 있는 모든 `Runnable` 인스턴스를 `wake()`시킨다.
`READY` 상태인 `Runnable` 인스턴스만 남도록 지속적으로 관리한다.
`timerQueue`에서 `TimerContainer` 데이터를 가져와서 메시지를 이동시킨다.


## Conclusion

KENS의 프로젝트는 (1) 네트워크 소켓 프로그래밍 (2) 네트워크 관련 시스템콜로 구성되어 있다.
과제를 구현할 때 시스템콜을 리턴하지 않으면 다른 프로그램(예를 들어, 네트워크 피어)가
실행되지 않는다는 사실이 디버깅에 꽤 유용하게 쓰였다.
또한 `System`에 정의된 스케줄링 알고리즘을 보면
타이머 큐에서 특정조건이 만족되지 않으면 시뮬레이션이 종료되지 않는데
이유는 이 글을 읽는 여러분들이 직접 찾아보기 바란다. (이유가 기억이 안난다...)
