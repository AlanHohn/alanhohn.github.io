---
layout: post
title: "Publishing JSON Schema Documentaton with Docson"
description: ""
category: articles
tags: []
---

For systems that have JSON data that's published as part of an API, there are
tools such as [Swagger][sw] / [OpenAPI][oa] and [RAML][ra] that can be used to
define REST endpoints and the data types for requests and responses. However,
for cases where JSON data isn't part of a REST API, such as documents in
MongoDB, files on a disk, or messages, [JSON Schema][js] provides a way to
specify what the JSON will look like in a way that covers all the possibilities
better than making example documents.

[sw]:http://swagger.io/
[oa]:https://openapis.org/
[ra]:http://raml.org/
[js]:http://json-schema.org/

JSON Schema is itself a JSON document, with pre-defined properties and types.
For example, a simple JSON schema might look like this:

```json
{
    "description": "Mailing address schema",
    "$schema": "http://json-schema.org/draft-04/schema#",
    "type": "object",
    "required": ["name", "zip"],
    "properties": {
        "name": {
            "description": "Full name of the recipient",
            "type": "string"
        },
        "addressType": {
            "description": "Whether the address is a residence, a business, or a post office box",
            "enum": ["residence", "business", "pobox"]
        },
        "street": {
            "description": "Street address and number",
            "type": "string"
        },
        "city": {
            "description": "City",
            "type": "string"
        },
        "state": {
            "description": "State code",
            "type": "string",
            "minLength": "2",
            "maxLength": "2"
        },
        "zip": {
            "description": "Zip code",
            "type": "string",
            "pattern": "^[0-9]{5}(?:-[0-9]{4})?$"
        }
    }
}
```

If well indented, the above is moderately readable, if verbose. However, it is
preferable to have tools to make it easier to navigate, and also to
perform validation. Validation at runtime of course depends on the
language, but the Python [jsonschema][pj] library provides an
easy means of testing JSON content to make sure the schema does what
it's supposed to.

[pj]:https://pypi.python.org/pypi/jsonschema

For navigation, there is a great tool called [Docson][ds] that generates
an interactive web page from a JSON schema. Docson is a JavaScript library,
so it can dynamically generate the documentation from any JSON schema file
it can fetch. Of course, because of cross-origin scripting concerns, there
are some limits as to what it can fetch, so the best approach is to grab
a local copy rather than serving from a Content Delivery Network (CDN).

[ds]:https://github.com/lbovet/docson

With a copy [downloaded][dl] and running, an example JSON file in the same
directory as Docson's index.html, and using Python's SimpleHTTPServer:

[dl]:https://github.com/lbovet/docson/archive/master.zip

```
$ python -m SimpleHTTPServer 9999
```

Docson produces a nice looking documentation page:

<img src="/post-images/docson.png" style="max-width:100%;max-height:250px;"/>

