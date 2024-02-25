---
title: 액터 모델 실습
subtitle: Leveraging Elixir GenServer
featuredImagePreview: actor-model.png
date: 2021-11-29T08:54:51+09:00
categories:
  - Computer
---

{{<bundle-image name="elixir-lang.png" caption="Elixir Programming Language">}}

요즘 나의 프로그래밍 공부는 Elixir를 공부하는 데 치중되어 있다.
Elixir는 강타입(Strongly typed), 동적타입(Dynamically typed), 함수형(Functional) 프로그래밍 언어다.
컴파일(`elixirc`) 뿐 아니라 인터랙티브 쉘(`iex`)과 스크립팅(`exs`)도 지원하기 때문에
함수형 언어인 것만 제외하면 파이썬이나 루비와 같은 스크립트 언어처럼 사용할 수 있다.
실제로 문법도 루비와 매우 흡사하기 때문에 파이썬이나 루비를 배웠던 사람이라면 큰 어려움없이 흡수할 수 있다.

함수형 언어에 한번 빠지니 다시 돌아가기가 너무 어렵다.
Elixir 전에는 F#을 주로 썼는데 F#은 아쉬운 점이 많았다.
Pattern Matching, Active Pattern이나 Algebraic Data Type 등 언어의 기능이
매우 강력해서 원하는 로직을 구현하는 것이 아주 즐거웠지만,
실제로 시스템을 구현하기 위해 C#으로 구현된 닷넷 에코시스템에 의존해야 했기 때문이다.
F#에서 C#으로 작성된 라이브러리를 사용할 수 있기는 하지만 Interop이 부자연스럽고 불편한 점이 많았다.
게다가 F#으로 작성된 라이브러리는 완성도가 낮은 경우가 많았다.
프로젝트를 실제로 진행하기에는 껄끄러운 점이 많았던 게 사실이다.
차라리 함수형 패러다임을 기꺼이 버리고 C#을 사용하는 게 나을 지경이다.

한편 Elixir는 erlang을 기반으로 작성되었고
동적 타입이라는 큰 차이점을 제외하면 F#처럼 언어적 특성이 매우 뛰어나다.
Phoenix, Ecto, Oban 등 Elixir로 작성된 프레임워크가
완성도가 매우 높고 프로젝트에서 실제로 사용하기에 무리가 없다.
Python이나 Ruby를 사용한 경험이 있다면 사고의 경계를 확장하기 위해
다음 언어로 Elixir를 배우는 것은 아주 좋은 선택이 될 것 같다.

# Actor Model in Elixir

Elixir는 언어적 단계에서 Actor Model을 지원한다. Akka와 같은 프레임워크가 필요없다.
Actor가 필요한 Stateful 시스템을 구현한다면 Elixir만큼 편리한 언어가 없을 것이다.

Elixir는 기본적으로 `Process` 모듈을 통해 프로세스를 관리한다.
여기서 프로세스란 OS에서 제공되는 프로세스가 아니라 어플리케이션 레벨의 경량 프로세스를 말한다.
`Process`는 각자 상태(State), 메시지 큐(Message Queue), 메시지 전송(Message Sending) 기능을
가지고 있고 다른 프로세스와 고립되어(기본적으로 에러를 전파하지 않는다) Elixir Actor Model의 가장 기초적인 뼈대가 된다.

다음을 통해 `Process`를 이해해보자.

``` elixir
# This spawns a process which
# print "hello!" and dies immediately
pid = spawn(fn -> IO.puts "hello!" end)
# It prints "hello!"

# This returns `false`
Process.alive?(pid)

# The main process itself is also a process
# `self()` returns the pid of the calling process
mother_process = self()
# `spawn` returns the pid of the spawned process
child = spawn(fn -> send(mother_process, {self(), "hi! mom"}) end)

# A process can receive a message from other processes
# with `receive` keyword
receive do
  {^child, msg} -> IO.puts "A letter from the child: #{msg}"
end
```

하지만 `Process`에는 너무 기본적인 기능만 구현되어 있어서 사용하기 쉽지 않다.
그렇기 때문에 `Process`가 서로 메시지를 주고 받을 수 있고,메시지 큐를 처리하며, 서로 고립되어 있다는 특성만 알고 넘어가자.
대신, 실제로 유용하게 사용할 수 있는 `Agent`, `GenServer`, `Task` 등을 살펴보자.
여기서는 Actor Model을 이해하는 데 유용한 `Agent`와 `GenServer`를 소개할 것이다.

# Agent

`Elixir`의 `Agent`를 이용하면 Actor Model의 상태 관리를 쉽게 구현할 수 있다.
`Agent`는 `Process` 모듈을 이용해 상태 관리를 편리하게 만든 모듈이다.

``` elixir
{:ok, pid} = Agent.start(fn -> [] end)

# The update function here returns :ok
Agent.update(pid, fn state -> [1 | state] end)

# The get function here return [1]
Agent.get(pid, fn state -> state end)
```

1. `start`(또는 `start_link`): 프로세스를 주어진 초기상태와 함께 시작시킨다.
2. `update`: 프로세스의 상태를 변경한다.
3. `get`: 프로세스의 상태를 얻는다.

* 상태를 초기화하고 변경하기 위해 모두 함수가 인자로 전달되었다.
* `start`를 사용해 시작된 프로세스는 Crash가 발생할 경우 부모 프로세스에 Crash가 전파되지 않는다 그러나 `start_link`를 사용하면 부모 프로세스에 crash가 전파된다.

`Agent`를 이용해 간단한 스택을 관리하는 프로세스를 구현해보자.
`get`, `update`, `get_and_update`로 상태 관리를 쉽게 구현할 수 있다.

``` elixir
defmodule Stack do
  def start_link(opts \\ []) do
    Agent.start_link(fn -> [] end, opts)
  end

  def push(pid, item) do
    Agent.update(pid, fn stack -> [item | stack] end)
  end

  def pop(pid) do
    Agent.get_and_update(pid, &do_pop/1)
  end

  defp do_pop([]), do: {nil, []}
  defp do_pop([hd | tl]), do: {hd, tl}
end
```

# GenServer

`Agent`를 이용해 상태 관리를 위한 Actor Model를 구현했다.
하지만 `Agent` 모듈에는 Actor Model의 메시지 큐(Message Queue, 혹은 메일 박스) 개념이 잘 드러나 있지 않다.
이에 반해 `GenServer`는 Actor Model의 메시지 큐, 행동방식(Behavior)까지 쉽게 구현할 수 있게 되어있다.

{{<bundle-image name="actor-model.png" caption="Actor Model 다이어그램">}}


``` elixir
defmodule Stack do
  use GenServer

  # Client API
  # This helps a client interact easily with
  # this GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def pop(server) do
    GenServer.call(server, :pop)
  end

  def push(server, item) do
    GenServer.cast(server, {:push, item})
  end

  # GenServer callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(:pop, _from, []]) do
    {:reply, nil, []}
  end

  @impl true
  def handle_call(:pop, _from, [hd | tl]) do
    {:reply, hd, tl}
  end

  @impl true
  def handle_cast({:push, item}, stack) do
    {:noreply, [item | stack]}
  end
end
```
* `init` : 초기 상태를 정의한다.
* `handle_call` : 클라이언트의 동기 호출(Synchronous Call)을 담당한다.
  - Message, Caller, State를 함수 인자로 받는다.
  - Caller는 값이 반환될 때까지 대기한다(Waiting).
  - `{:reply, Response, New State}`을 반환한다.
* `handle_cast` : 클라이언트의 비동기 호출(Asynchronous Call)을 담당한다.
  - Message, State를 함수 인자로 받는다.
  - Caller는 값이 반환되는 것을 대기하지 않는다.
  - `{:noreply, New State}`을 반환한다.

이런 방식으로 `GenServer`의 콜백함수들을 정의함으로써 메시지에 따른 Actor Model의 행동방식을 정의할 수 있다.
구체적으로 여기서 메시지는 `:pop`, `{:push, item}`이고 그에 따른 행동방식이 `handle_*` 함수 안에 정의되어 있다.
물론 먼저 들어온 순서에 따라서 메시지가 처리된다.

`GenServer`의 강점은 이처럼 Actor Model의 구현 방식이 제시되어 있어 그 틀을 따라가기만 하면
쉽게 구현할 수 있다는 점도 있지만, Server(메시지를 받아 처리하는 측)와 Client(메시지를 보내는 측)의 코드를 분리해 구현할 수 있다는 점도 크다.
예를 들어 `Process`나 `Agent`를 사용하면 다음과 같은 코드를 작성하기 쉽다.

``` elixir
def update_state(pid) do
  # Code here runs on the client side
  Agent.update(pid, fn state ->
    # Code here runs on the server side
  end)
end
```

기능이 작동하는 데는 문제는 없으나 Client와 Server에서 작동하는 코드가 하나의 함수에 작성되기 떄문에,
구분이 불명확해져 Client와 Server의 행동을 해석하기 어렵게 만든다.
Server에 의도치않게 동기식으로 무거운 연산을 올리는 등의 실수를 유발하기 쉽다.

`GenServer`에서의 콜백 함수는 철저히 Server에서 작동하는 코드다.
Client 측이 사용하는 함수는 위의 예제처럼 따로 작성하면 된다.
Server와 Client의 경계가 구분된 함수로 명확하게 들어나면서 시스템의 요구사항에 맞는 설계를 하기 쉬워진다.

## 마치면서

Actor Model의 특성을 Elixir의 `Process`, `Agent`, `GenServer`를 통해 이해해봤다.
Actor라는 작은 단위를 이해했으니 전체 시스템을 이해하기 위해 Actor들이 서로 협력하는 법을 살펴봐야할 차례다.
Akka에서와 같이 Elixir에서도 Supervisor와 Supervision Tree 개념이 있다.
다음에는 이 부분을 살펴볼 예정이다.

## 참고 자료

1. Elixir Agent: https://elixir-lang.org/getting-started/mix-otp/agent.html
2. Elixir GenServer: https://elixir-lang.org/getting-started/mix-otp/genserver.html
3. Elixir GenServer: https://hexdocs.pm/elixir/GenServer.html#content