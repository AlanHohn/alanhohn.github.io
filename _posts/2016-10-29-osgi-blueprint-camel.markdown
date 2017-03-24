---
layout: post
title: "OSGi Zero Code Declarative Service with Apache Camel"
description: ""
category: articles
tags: []
---

```
2016-10-29 21:42:46,999 | INFO  | pool-8-thread-1  | BlueprintContainerImpl           | 12 - org.apache.aries.blueprint.core - 1.6.2 | Bundle org.anvard.karaf.greeter.spanish/1.0.0.SNAPSHOT is waiting for namespace handlers [http://camel.apache.org/schema/spring]
```

```
Caused by: java.lang.ClassNotFoundException: org.anvard.karaf.greeter.api.Greeter not found by org.anvard.karaf.greeter.spanish [56]
```

```
karaf@root()> camel:route-list
 Context           Route          Status              Total #       Failed #     Inflight #   Uptime          
 -------           -----          ------              -------       --------     ----------   ------          
 spanish-greeter   route1         Started                   0              0              0   26.794 seconds  
```

