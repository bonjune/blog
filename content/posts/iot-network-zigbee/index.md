---
title: "IoT를 이루는 네트워크: ZigBee"
date: 2023-06-23T05:26:32+09:00
categories: ["Software Engineering"]
draft: true
---

## Overview

IoT (Internet-of-Things)에는 여러 네트워크 프로토콜이 혼재한다.
전원이 항상 연결되어 있거나 주기적으로 충전해줄 수 있는 경우가 많지 않기 때문에 저전력 요구사항을 요구하기 때문에 이를 충족시키기 위한 프로토콜이 필요하다.
대표적으로 ZigBee와 Z-Wave, BLE(Bluetooth Low Energy) 등이 이러한 요구사항을 충적하며,
전력이 안정적으로 공급될 수 있다면 WiFi 등을 사용할 수도 있다.

이 중 ZigBee는 이러한 저비용, 저전력, 무선이라는 요구사항을 위해 ZigBee alliance에서 개발한 통신 프로토콜이다.
ZigBee는 레이어 구조(layered architecture)를 가지며, 물리(physical) 및 링크(link) 레이어와 네트워크 레이어(NWK), 어플리케이션 레이어로 이루어진다.
ZigBee Alliance가 제공하는 어플리케이션 레이어 프레임워크에는 어플리케이션 지원 서브레이어(APS)와 ZigBee device objects(ZDO)가 있다.

{{<bundle-image name="zigbee-stack-architecture-overview.jpg" alt="zigbee architecture overview" width="75%">}}

## 물리 및 링크 레이어

ZigBee 네트워크는 868/915 MHz 또는 2.4 GHz 대역에서 운용된다.
CSMA-CA 또는 LBT 메커니즘을 사용해 무선 통신을 제어한다.

## ZigBee

### ZigBee 프로토콜 특성

ZigBee는 저전력 및 저대역폭 프로토콜로 센서나 소형 디바이스를 근거리(10~100m)에서 연결하기 위해 사용한다.
사용 전력이나 환경에 따라 10~100미터 정도를 도달할 수 있으며, Bluetooth보다 단순한 프로토콜을 제공한다.
ZigBee 통신은 128비트 대칭키로 암호화되며 최대 250 Kb/s (킬로비트) 까지 통신이 가능하다.

ZigBee 네트워크에는 다음 세가지 디바이스가 참여한다.

1. ZigBee Coordinator: 네트워크를 제어하는 중앙 디바이스다. 보통 네트워크에서 유일하게 존재한다.
2. ZigBee Router
	- 신호 중개기(repeater)다. ZigBee 신호를 받아 더 멀리 보낸다.
	- 수면(sleep) 하면 안된다. 네트워크가 끊어질 수 있다. 안정적인 전원 공급이 필요하다.
	- 네트워크에 새로운 노드가 참여하도록 할 지 결정할 수 있다.
1. ZigBee End Device
	- 신호를 발생시키는 센서나 신호를 받아 행동을 수행하는 디바이스라고 생각하면 된다.
	- 수면(sleep)이 가능하다. 따라서 배터리 전원을 사용하기 적합하다.
	- 하나의 부모 노드만 가진다. (a coordinator or a router)

### ZigBee 프로토콜 개념

인터넷 프로토콜로 생각하면 Link Layer Protocol이다.
OSI 모델에서는 링크 및 물리 레이어로 보면 된다.
IEEE 802.15.4 표준을 따르며 이는 6LoWPAN, Thread, Z-Wave 또한 사용하는 표준이다.
IEEE 802.15.4에는 사용할 수 있는 대역이 여러가지가 있는데 ZigBee는 2.4GHz를 사용하며 Z-Wave는 나라마다 다를 수 있지만 8/900MHz를 사용한다.

#### ZigBee Endpoint (엔드포인트)

TCP/IP의 포트 개념이다. TCP에서 한 머신이 네트워크 상에서 여러 포트를 사용할 수 있는 것처럼 ZigBee 또한 한 디바이스가 여러 엔드포인트를 가질 수 있다.

### ZigBee Cluster

ZigBee는 네트워크에서 운용할 수 있는 표준 어플리케이션을 정의한다.
해당 어플리케이션들은 ZigBee Cluster Library Specification에 정의되어 있다.
한 클러스터는 어플리케이션 통신의 타입을 지정하며, 어플리케이션 통신 타입은 정수로 된 ID를 가진다.
어플리케이션 통신 타입은 클라이언트 또는 서버로 나뉘며 일반적으로 서버는 클라리언트보다 더 자주 실행되고, 클라이언트는 서버에 연결하려고 한다. 하지만 서버와 클라이언트의 명확한 구분은 없다.

ZigBee 컨트롤러는 클러스터를 두 엔드포인트에 각각 연결할 수 있다.
한 쪽에는 클러스터의 서버 타입, 또 다른 한 쪽에는 클러스터의 클라이언트 타입을 지정한다.

일반적인 클러스터 외에도 그룹 클러스터가 있다.
한 엔드포인트는 여러 그룹에 소속될 수 있으며 디바이스는 어떤 그룹에 속해있었는지 기억한다.
그룹은 엔드포인트처럼 작동할 수 있어서, 그룹에 메시지가 오면 그룹 네트워크에 있는 모든 디바이스에 브로드캐스트된다.
이를 통해 한 스위치로 여러 개의 전등을 키고 끌 수 있는 기능을 구현할 수 있다.

또한 씬(Scene) 클러스터도 있다.
씬 클러스터를 이용하면 클러스터를 구현할 때의 설정값을 기억하도록 할 수 있다.
예를 들어 전등은 밝기를, 블라인드 커튼은 높이를 기억할 수 있다.
각 디바이스는 여러 씬을 기억할 수 있다.
이를 통해 디바이스들을 제어할 때 씬 ID만을 이용해 그룹 안에 있는 여러 디바이스를 제어할 수 있으므로 통신 대역폭을 절약할 수 있다.





ZigBee 스틱: [SONOFF ZBDongle P 범용 지그비 3.0 USB 스틱 게이트웨이 동글 플러스 분석기, USB 인터페이스 캡처 패킷, ZHA ZigBee2MQTT|스위치| - AliExpress](https://ko.aliexpress.com/item/1005003637706867.html?spm=a2g0o.detail.100009.3.65417e16NI4riT&gps-id=pcDetailLeftTopSell&scm=1007.13482.271138.0&scm_id=1007.13482.271138.0&scm-url=1007.13482.271138.0&pvid=a7eaa535-2f27-4364-bdb5-298e06076ef5&_t=gps-id%3ApcDetailLeftTopSell%2Cscm-url%3A1007.13482.271138.0%2Cpvid%3Aa7eaa535-2f27-4364-bdb5-298e06076ef5%2Ctpp_buckets%3A668%232846%238116%232002&pdp_npi=3%40dis%21KRW%217554.0%216798.0%21%21%21%21%21%4021015b7d16874847599967737e76c2%2112000028014985500%21rec%21KR%21&gatewayAdapt=glo2kor)



## Thread



## Matter

Matter는 정확히 말하면 네트워크 프로토콜이 아니라 규격(Standard)이다.
2년마다 업데이트되며 IoT 디바이스 를지원하는 네트워크 프로토콜, behavior 등을 표준화한다.

## Home Control System

- Amazon Alexa
- Samsung SmartThings
- AppleHomeKit
- HomeAssistant
