---
title: 컴퓨터와 시간
subtitle: 컴퓨터의 시계는 어떻게 작동할까
date: 2021-08-28T12:35:23+09:00
categories: ["computer"]
featuredImagePreview: pat_sync.jpg
tags: ["computer", "systems"]
---

{{<bundle-image name="pat_sync.jpg">}}

# 거대한 시차

해외로 가는 비행기표를 찾아볼 때 우리는 우리의 표준시와 도착지의 표준시를 비교한다.
서울은 뉴욕보다 14시간 빠르다.
일광절약제가 적용되는 때에는 13시간 빠르다.
그래서 인천에서 출발할 때의 시각은 한국표준시로 읽고 뉴욕에 도착할 때의 시각은 동부시간대로 읽는다.
지구 상에 어디에 있든, 시간대는 아주 정확하게 구분되어 있고 일정한 간격으로 흘러가고 있다.

현대 사회에서 시각을 읽는 것은 아주 쉬운 일이다.
스마트 워치를 사용하거나, 스마트폰을 열거나 랩탑이나 데스크탑을 키면 1초단위로 시각을 아주 정확하게 보여준다.
콘서트 티케팅이나 대학 수강신청처럼 1초 단위로 희비가 갈리는 이벤트에 있어서도
다들 디지털 시계를 가지고 있기 때문에 티케팅 서버나 대학 서버 시각을 정확하게 맞춰서 접속할 수 있다.

여기서 질문.

* 서울에서 시계가 18시를 가르킬 때, 뉴욕에서 시계가 정말로 정확하게 4시를 가르킬까? (시차 14시간)
* 티케팅 시작이 13시다. 내 시계가 13시일 때, 정말로 티케팅 서버의 시계도 13시를 가르킬까?

서울에서 시계가 정확히 18시일 때, 뉴욕에서 시계가 정말로 딱 4시를 가르키는지 확인해보기 위해 친구를 뉴욕에 보냈다(고 해보자).
18시가 되기 전에 전화를 걸어서 내가 18시일 때 친구는 4시인지 확인해보기로 했다.
친구랑 전화해보니 대충 맞는 거 같은데... 의문이 든다.
내가 보는 시계가 정말 '완벽하게 정확한' 시계일까? 친구가 보는 시계는? 친구는 4시가 되는 걸 보자마자 내게 알려준 걸까? 전화로 친구의 목소리가 '즉시' 전달 된걸까?

**놀랍게도 여기서 우리가 '그렇다'라고 확실하게 말할 수 있는 질문이 하나도 없다.** 내가 보는 시계도, 친구가 보는 시계도 정확하지 않고, 친구가 4시를 보고 바로 말했는지도 확실하지 않고 전화에 딜레이가 있었다고 보는 게 현실적이다. 한국의 18시와 뉴욕의 4시, 정말로 그런지 측정하는 건 현실적으로 불가능한 일이다.

내가 티케팅 서버의 시간을 '완벽하게' 정확하게 알고 있다면, 나는 티케팅이 열리자 마자 가장 먼저 티케팅 서버에 접속할 수 있어야 한다. 하지만 그런 일이 가능한 사람은 없다. 티케팅 서버의 시간을 내가 완벽하게 정확히 아는 게 불가능하기 때문이다. 왜 그런걸까. 두가지 이유다.

시간을 재는 측정 방법 자체가 완벽하지 않고, 시간을 공유하는 방법도 완벽할 수가 없기 때문이다. 우리가 가장 흔히 쓰는 시계인 컴퓨터는 어떻게 시간을 관리하는 지 알아보면서 문제를 좀 더 자세히 파악해보자.

컴퓨터들도 서울과 뉴욕에 있는 두 친구처럼 각자 시계를 본다. 컴퓨터는 두 개의 시계를 가지고 있는데, 하나는 마더보드에 딸린 CMOS Clock이다. CMOS Clock은 컴퓨터의 전원이 꺼져도 배터리를 이용해 시간을 계속해서 잴 수 있다. 또 하나는 CPU의 Clock Frequency다. CPU가 1초에 얼마나 많은 명령어를 처리할 수 있는지를 이용해서 시간을 잰다. 이런 식으로 시간의 일정한 간격을 잴 수 있다.

컴퓨터의 전원이 켜지고 운영체제가 실행되면, 운영체제가 시간을 관리하기 시작한다. 운영체제가 관리하는 시간을 System Time이라고 한다. System Time은 특정 시간(epoch)을 기준으로 얼마나 많이 시간이 흘렀는지를 이용해 시간을 잰다. Unix 시스템의 경우 1970년 1월 1일 00:00 UTC를 기준으로 한다.

{{<bundle-image name="system_time_config.png" caption="System Time은 변경될 수 있다">}}

하지만 System Time은 쉽게 신뢰할 수 없다. 운영체제에 의해 변경될 수 있기 때문이다. OS 설정이나 system call을 통해 System Time을 변경할 수 있다. 어플리케이션에서 System Time을 사용할 때는 정말 신뢰할 수 있는지 검증해봐야 한다. System Time은 OS의 작동이나 설정, system call에 따라 갑자기 뒤로 갈수도, 앞으로 튈수도 있다. System Time이 계속해서 일정하게 증가할 것이라는 건 잘못된 설정이다. 우리가 보는 벽걸이 시계도 초침을 돌려서 보이는 시각을 바꿀 수 있다. 컴퓨터의 System Time도 똑같은 셈이다.

# 시계 다시 맞추기

지금까지 컴퓨터의 시각의 기준(예를 들어, Unix Epoch)과 컴퓨터가 시간을 재는 법(CMOS Clock, CPU Clock Frequency)를 알아봤다. 그런데 컴퓨터가 시간을 정말 정확하게 잴까? 우리가 쓰는 시계가 오래쓰면 점점 느려지거나 빨라지듯이 컴퓨터의 시계에도 오류가 쌓인다. 다시 맞춰줘야 한다. 컴퓨터도 서울과 뉴욕에 있는 두 친구처럼 서로 시간을 비교해서 검사한다. 여기서 가장 널리 쓰이는 방식이 Network Time Protocol(NTP)다. 자세한 내용은 https://en.wikipedia.org/wiki/Network_Time_Protocol 을 참고하자.

NTP를 간단하게 설명하면

1. 다른 컴퓨터에 시간을 물어본다. 이 때 요청을 보낸 시각을 측정한다. (t1)
2. 요청을 받은 컴퓨터에서 요청을 받은 시각을 측정한다. (t2)
3. 요청을 받은 컴퓨터에서 다시 내 컴퓨터에 신호를 보낸다. 이 때의 시각을 측정한다. (t3)
4. 내 컴퓨터에 신호가 도착한 시각을 측정한다. (t4)

이 때 t1, t2, t3, t4를 비교해 서로 시간에 오차가 있는지 확인해 볼 수 있다. 물론 내가 시각을 물어볼 컴퓨터가 '정확한' 시각을 알고 있다고 가정해야 한다. 그렇기 때문에 그런 시각을 가지고 있는 서버는 보통 구글, 애플, 정부 등 신뢰할 수 있는 조직에서 운영하고 있다.

```
t1: 2021-08-21T08:56:15.073958Z
t2: 2021-08-21T08:56:15.213376928Z
t3: 2021-08-21T08:56:15.213376929Z
t4: 2021-08-21T08:56:15.150058Z
```

구글의 time server인 time.google.com에 NTP를 통해 시각을 비교해본 결과다.
내 컴퓨터에서 측정한 시각인 t1, t4와 time.google.com에서 측정한 시각인 t2, t3를 비교해보면 내 컴퓨터의 시각이 구글 time server보다 조금 뒤쳐졌음을 알 수 있다.