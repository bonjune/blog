---
title: "Odroid 개발보드에서 Zig와 C를 같이 사용하기"
date: 2023-06-29T13:00:00+09:00
categories: ["Software Engineering"]
featuredImagePreview: ziglang.png
---

{{<bundle-image name="odroidn2plus.jpg" alt="Odroid-N2+ Development Board" caption="Odroid-N2+ 개발 보드"  width="50%">}}

[Odroid-N2+](https://www.hardkernel.com/shop/odroid-n2-with-4gbyte-ram-2/) 개발 보드를 구입해서 네트워크 연결을 관리하는 프로그램을 작성하는 실험을 해보고 있다.
개발 보드에 설치된 우분투 리눅스에서 블루투스나 ZigBee 등 네트워크 프로그래밍을 어떻게 하는지 방법을 찾아보고 있다.

제일 먼저 리눅스의 블루투스 서브시스템인 [BlueZ](http://www.bluez.org/about/)를 사용해보고 싶었다.
ZigBee 도 사용해보고 싶은데 ZigBee 동글과 센서를 알리에서 주문했더니 배송이 꽤 걸린다고 해서 블루투스 먼저 시도해봤다.

지금 사용하는 N2+ 보드는 성능이 꽤 나오는 보드이지만, 더 성능이 제한되는 소형 보드에서도 실행 가능한 프로그램이면 좋겠어서 C나 C++의 성능이 나오는 프로그래밍 언어를 찾아보았다.

## Zig를 선택하고 빌드 시스템 구축하기

제일 먼저 내가 익숙해하면서도 빠른 개발이 가능한 Python을 검토해보았다.
Python도 저수준의 프로그래밍이 가능하지만, 파이썬에서 BlueZ를 사용할 수 있는 [pybluez](https://github.com/pybluez/pybluez) 프로젝트가 개발이 중단되어 있는 상태라 Python은 제외하였다.

C나 C++를 사용해야 싶었지만 언어의 개발 경험이 좋지도 않고 최근 C나 C++을 대체할 수 있는 언어가 많이 나와있기 때문에 대체 언어들을 찾아보았다.

제일 먼저 살펴본 언어는 그 유명한 Rust다.
Rust는 C와 상호운용이 가능하면서도 메모리 안전한 프로그램을 작성하고, 성능도 준수한 프로그램을 작성할 수 있다.
그런데 C로 작성된 BlueZ 라이브러리를 사용하려면 C로 작성된 프로그램과 Rust로 작성한 프로그램을 링킹하는 과정이 필요하다.
이러면 Rust 컴파일러와 C 컴파일러를 같이 사용하면서 빌드 시스템이 복잡해질 수 있기 때문에 일단 여기까지 조사하고 넘어갔다.

{{<bundle-image name="ziglang.png" alt="Zig Programming Language" caption="Zig Programming Language"  width="50%">}}

그 다음 살펴본 언어는 [Zig](https://ziglang.org/) 다.
Zig는 Rust처럼 C 스타일 프로그래밍 언어로, 메모리 안전성과 명시적인 제어 흐름, 컴파일시간 계산이 특징인 언어다.
Zig의 강점은 C, C++ 등 다른 언어로 작성된 프로그램과 상호운용이 아주 쉽다는 점이다.
Zig의 빌드 시스템(`zig build`)을 이용하면 C, C++로 작성된 언어를 쉽게 Zig 프로그램과 통합할 수 있다.
프로그래밍하는 것처럼 빌드 시스템을 꾸릴 수 있기 때문에 빌드 시스템을 구축하는 것도 어렵지 않다.

## Zig 프로젝트와 BlueZ 통합하기

BlueZ 라이브러리를 Zig 코드와 통합해보자.
일단 [BlueZ » Download](http://www.bluez.org/download/) 에서 유저 공간에서 사용할 수 있는 BlueZ 패키지를 내려받고 프로젝트에 위치시킨다.
프로젝트 구조는 다음과 같다. (`tree -L 2`)

```
.
|-- build.zig
|-- libs
|   `-- bluez-5.66
|       |-- ...
|       |-- lib
|       |-- src
|       |-- test
|       |-- tools
|       `-- unit
|-- src
    |-- bluetoothlib.zig
    `-- main.zig
```

libs 폴더를 두어 여기에 `bluez-5.66` 패키지를 위치시켰다. BlueZ에서 제공하는 라이브러리를 사용할 것이므로 `bluez-5.66/lib`에 있는 `bluetooth.c`, `uuid.c`, `sdp.c`, `hci.c`를 컴파일해야 한다.
이 소스코드들은 `bluez-5.66`에 있는 헤더파일들에 선언된 프로토타입과 전처리 매크로가 필요하므로 컴파일 옵션에 `-I`로 추가한다.
또한 BlueZ는 libc에 의존성이 있으므로 `exe.linkLibc()`를 통해 링킹해준다.
libc의 함수들을 사용할 수 있도록 `/usr/include` 또한 `-I` 옵션으로 포함시켜준다.
Zig의 빌드시스템에는 암묵적으로 libc가 포함되지 않아 모두 명시적으로 링킹해주어야한다.

```zig
// build.zig

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "opera",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();
    exe.addCSourceFiles(&.{
        "./libs/bluez-5.66/lib/bluetooth.c",
        "./libs/bluez-5.66/lib/hci.c",
        "./libs/bluez-5.66/lib/uuid.c",
        "./libs/bluez-5.66/lib/sdp.c",
    }, &.{
        "-Ilibs/bluez-5.66",
        "-I/usr/include",
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}

```

시스템에 연결된 블루투스 디바이스를 찾아 소켓을 여는 간단한 프로그램을 작성해보자.

```zig
// main.zig
const std = @import("std");
const btlib = @import("bluetoothlib.zig");

pub fn main() !void {
    const dev_id = try btlib.get_route();
    const sock = try btlib.get_socket(dev_id);
    std.debug.print("dev_id = {d}, sock = {d}\n", .{ dev_id, sock });
}
```

`bluetoothlib.zig`에서는 BlueZ Library에서 정의한 함수에 접근할 수 있도록
C 구조체와 함수의 프로토타입을 지정한다.
그리고 Zig 스타일의 함수로 감싸 퍼블릭 함수로 제공한다.

```zig
// bluetoothlib.zig

// C API for the Linux Bluetooth stack

/// Bluetooth device address is a contiguous 6-byte array
pub const bdaddr_t = extern struct {
    b: [6]u8 align(1),
};

extern "c" fn hci_get_route(bdaddr: ?*bdaddr_t) c_int;
extern "c" fn hci_devid(str: *const u8) c_int;

pub fn get_route() !i32 {
    const dev_id = hci_get_route(null);
    if (dev_id < 0) {
        return BluetoothError.AdapterNotFound;
    }
    return @as(i32, dev_id);
}

pub fn get_socket(dev_id: i32) !i32 {
    const sock = hci_open_dev(dev_id);
    if (sock < 0) {
        return BluetoothError.CantOpenSocket;
    }
    return @as(i32, sock);
}

```

## 크로스 컴파일 개발 환경 만들기

내 랩탑은 x86 리눅스이므로 `zig build`를 실행하면 `x86-64-linux-gnu` 로 컴파일된다.
컴파일 속도는 내 랩탑이 빠르므로 내 랩탑에서 빌드하고 그 결과를 개발 보드에서 실행하고 싶다.
따라서 빌드 시에 컴파일 대상을 `aarch64-linux-gnu`로 변경한다.
aarch64 리눅스 시스템의 GNU LIBC(GLIBC)를 사용한다는 뜻이다.
다음과 같이 Makefile을 작성해 ssh를 이용해 개발 보드에서 실행해보자.

```Makefile
TARGET_BINARY = ./zig-out/bin/opera
TARGET_MACHINE = /* REDACTED */

.PHONY: build send run connect

all: build send run

build:
	zig build -Dtarget=aarch64-linux-gnu
	@echo "Build complete."

send:
	scp $(TARGET_BINARY) $(TARGET_MACHINE):~
	@echo "Binary sent to target machine."

run:
	ssh $(TARGET_MACHINE) ~/opera
	@echo "Target binary executed on target machine."

connect:
	ssh $(TARGET_MACHINE)

```

```
>> make
dev_id = 0, sock = 3
```

잘 된다!


## 배운 것들

- 실행 파일을 빌드할 때 서로의 프로토타입을 가진 오브젝트끼리 링크해야 한다.
- 프로토타입은 헤더 파일이나 `extern ...` 등을 이용해 선언할 수 있다.
