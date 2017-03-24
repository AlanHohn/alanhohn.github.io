---
layout: post
title: "Go Archive Support"
description: ""
category: articles
tags: []
---

I happened to be working on a REST microservice recently, and ended up
implementing it in the [Go][golang] programming language. I was pleased
by the experience, especially when it came to integrating the HTTP
support with handling of zip archives.

One of the functions of the microservice is to accept files in ZIP
format and to process the files it finds inside. I wanted to find a
way to avoid generating a lot of temporary files on disk, since once
the service was done with the uploaded file it didn't need to hang onto
it any longer.

Being relatively new to Go, it takes me a little time looking over the
documentation, searching for similar examples, and putting things together.
The documentation we need for this case is for [net/http][1] and also for
[archive/zip][2].

First we start with a basic example for setting up an HTTP microservice and
dispatching incoming requests to various functions. This just takes a
couple lines of code. We start with a handler function with the right
signature, then register it with the http package. Then we start the server.

```go
func FileUpload(w http.ResponseWriter, req *http.Request) {
  ...
}

http.HandleFunc("/upload", FileUpload)
http.ListenAndServe(":8080", nil)
```

Next we can write the body of the hanlder function. ([This article][5] was
helpful.) Any kind of HTTP request will get routed to this function, so we have
to make sure this is a POST. We can then start to unpack the POST data. We will
assume the uploaded file is part of an HTTP [multipart request][3]. Fortunately
Go contains [explicit support][4] for finding the pieces of a multipart request
and allowing us to select the one we want. This functionality is used under the
covers in the `http` package.

```go
func FileUpload(w http.ResponseWriter, req *http.Request) {
  if req.Method == "POST" {
    err := req.ParseMultipartForm(32 << 20)
    if err != nil {
      http.Error(w, err.Error(), http.StatusBadRequest)
      return
    }
    file, _, err := req.FormFile("uploadfile")
    if err != nil {
      http.Error(w, err.Error(), http.StatusBadRequest)
      return
    }
    defer file.Close()
    size, err := file.Seek(0, 2)
    if err != nil {
      http.Error(w, err.Error(), http.StatusBadRequest)
      return
    }
    file.Seek(0, 0)
    ParseZipFile(file, size)
    if err != nil {
      http.Error(w, err.Error(), http.StatusBadRequest)
      return
    }
  } else {
    http.Error(w, err.Error(), http.StatusBadRequest)
  }
}
```    

The parameter in `ParseMultipartForm` specifies how much memory to set aside
for the parsing; in this case 32MB. Any larger request will be spooled to disk
temporarily.  The `FormFile` call then looks at the multipart request to find
that field and gives us back a pointer to it. (It would also give us a
`FileHandler` object we can use to get the name and headers, but since we don't
need it we ignore it.)

This is where things get tricky. The pointer we get is to a `multipart.File`.
This type provides a number of useful interfaces: `io.Reader`, `io.ReaderAt`,
`io.Seeker`, and `io.Closer`. However, when we look at the `archive/zip`
package, this still doesn't quite line up with what we need. To start working
with a zip file, we need a variable of type `zip.Reader`. We can't use the
regular function `OpenReader` because this wants a file name on disk, and we're
trying not to separately write the zip content to a disk file.

Instead, we see that there is a `NewReader` function:

```go
func NewReader(r io.ReaderAt, size int64) (*Reader, error)
```

To call this one we need `io.ReaderAt`, which we have. (This is a reader that also supports
random access.) However, we also need a size. (This is necessary because the [zip format][6]
puts the table of contents, a.k.a. the central directory, at the end.) We don't have the size,
but we can get it, because our `multipart.File` supports `io.Seeker`, and that means we can
call `Seek`. If we tell `Seek` to jump to the end of the file it will return the position in
bytes that results, which is the size. (The parameters `0, 2` say to jump zero bytes from the
end.) When then jump back to the beginning.

With that insight, which of course I found by a judicious Google search, things
get much easier. The function to parse the zip file is very straightforward and
doesn't know anything about HTTP.

```go
func ParseZipFile(archive io.ReaderAt, size int64) error {
  reader, err := zip.NewReader(archive, size)
  if err != nil {
    return err
  }
  defer reader.Close()
  for _, file := range reader.File {
    // Do something useful with each file
    // file.Name has the name of the file
  }
}
```

There is one limitation in reading the zip file. The file variable that we get
for each entry in the zip file is of type `zip.File`. This type has an `Open`
function that returns an `io.ReadCloser`. This means we can read and we can
close, but we can't seek in this file or access the contents randomly. This
makes sense, because the files in the zip are being decompressed on-the-fly as
we read them, so it's not really possible for the zip reader to jump around
within the *uncompressed* contents because there's no guaranteed correlation of
compressed bytes to uncompressed. If we do need random access to one of the
files in the zip, we're forced to spool it to disk ourselves first.

Overall I tend to enjoy working in Go whenever I get the opportunity. I find
that I tend to write relatively few lines of code (even with Go error handling,
which tends to make the code more verbose).  At the moment, these lines of code
take me a decent amount of time to write because I spend a lot of time looking
up solutions. But the resulting code is elegant and the performant way of doing
things often ends up being the most natural.

[golang]:https://golang.org/
[1]:https://golang.org/pkg/net/http/
[2]:https://golang.org/pkg/archive/zip/
[3]:https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
[4]:https://golang.org/pkg/mime/multipart/
[5]:https://astaxie.gitbooks.io/build-web-application-with-golang/content/en/04.5.html
[6]:https://users.cs.jmu.edu/buchhofp/forensics/formats/pkzip.html

