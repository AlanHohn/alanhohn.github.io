#!/bin/bash
MY_DIR="$(cd "${0%/*}" 2>/dev/null; echo "$PWD")"

TODAY=$(date "+%Y-%m-%d")

cat >${MY_DIR}/_posts/${TODAY}-$1.markdown <<EOD
---
layout: post
title: ""
description: ""
category: articles
tags: [,]
---

EOD

