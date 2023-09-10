## open

```js

class ReadFileContext {
  constructor(callback, encoding) {
    this.fd = undefined;
    this.isUserFd = undefined;
    this.size = 0;
    this.callback = callback;
    this.buffers = null;
    this.buffer = null;
    this.pos = 0;
    this.encoding = encoding;
    this.err = null;
    this.signal = undefined;
  }

  read() {
    if (this.size === 0) {
      buffer = Buffer.allocUnsafeSlow(kReadFileUnknownBufferLength);
      offset = 0;
      length = kReadFileUnknownBufferLength;
      this.buffer = buffer;
    } else {
      buffer = this.buffer;
      offset = this.pos;
      length = MathMin(kReadFileBufferLength, this.size - this.pos);
    }

    const req = new FSReqCallback();
    req.oncomplete = readFileAfterRead;
    req.context = this;

    read(this.fd, buffer, offset, length, -1, req);
  }

  close(err) {
    const req = new FSReqCallback();
    req.oncomplete = readFileAfterClose;
    req.context = this;
    this.err = err;

    close(this.fd, req);
  }
}

function readFile(path, options, callback) {
  callback = maybeCallback(callback || options);
  options = getOptions(options, { flag: 'r' });
  const ReadFileContext = require('internal/fs/read/context');

  const context = new ReadFileContext(callback, options.encoding);
  context.isUserFd = isFd(path); // File descriptor ownership

  if (options.signal) {
    context.signal = options.signal;
  }
  if (context.isUserFd) {
    process.nextTick(function tick(context) {
      ReflectApply(readFileAfterOpen, { context }, [null, path]);
    }, context);
    return;
  }

  if (checkAborted(options.signal, callback))
    return;

  const flagsNumber = stringToFlags(options.flag, 'options.flag');
  path = getValidatedPath(path);

  const req = new FSReqCallback();
  req.context = context;
  req.oncomplete = readFileAfterOpen;   // <--
  binding.open(pathModule.toNamespacedPath(path),
               flagsNumber,
               0o666,
               req);
}

FSReqCallback {
    .context {
        .fd
    }
}

function readFileAfterOpen(err, fd) {
  const context = this.context; // 'this' is a FSReqCallback.

  if (err) {
    context.callback(err);
    return;
  }

  context.fd = fd;

  const req = new FSReqCallback();
  req.oncomplete = readFileAfterStat;
  req.context = context;
  binding.fstat(fd, false, req);
}

```

```c

static void Open(const FunctionCallbackInfo<Value>& args) {
  FSReqBase* req_wrap_async = GetReqWrap(args, 3);
  if (req_wrap_async != nullptr) {  // open(path, flags, mode, req)

    req_wrap_async->set_is_plain_open(true);

    AsyncCall(env, req_wrap_async, args, "open", UTF8, AfterInteger,
              uv_fs_open, *path, flags, mode);

  } else {  // open(path, flags, mode, undefined, ctx)
    // ...
  }
}

void AfterInteger(uv_fs_t* req) {
  FSReqBase* req_wrap = FSReqBase::from_req(req);
  FSReqAfterScope after(req_wrap, req);

  int result = static_cast<int>(req->result);
  if (result >= 0 && req_wrap->is_plain_open())
    req_wrap->env()->AddUnmanagedFd(result);

  if (after.Proceed())
    req_wrap->Resolve(Integer::New(req_wrap->env()->isolate(), result));
}
```

## stat


```c

static void Stat(const FunctionCallbackInfo<Value>& args) {

  // ...

  FSReqBase* req_wrap_async = GetReqWrap(args, 2, use_bigint);
  if (req_wrap_async != nullptr) {  // stat(path, use_bigint, req)

    AsyncCall(env, req_wrap_async, args, "stat", UTF8, AfterStat,
              uv_fs_stat, *path);

  } else {  // stat(path, use_bigint, undefined, ctx)
    FSReqWrapSync req_wrap_sync;

    int err = SyncCall(env, args[3], &req_wrap_sync, "stat", uv_fs_stat, *path);

    args.GetReturnValue().Set(arr);
  }
}

void AfterStat(uv_fs_t* req) {
  FSReqBase* req_wrap = FSReqBase::from_req(req);
  FSReqAfterScope after(req_wrap, req);
  FS_ASYNC_TRACE_END1(
      req->fs_type, req_wrap, "result", static_cast<int>(req->result))
  if (after.Proceed()) {
    req_wrap->ResolveStat(&req->statbuf);
  }
}

```

## read


```js

function readFileAfterStat(err, stats) {
  const context = this.context;

  if (err)
    return context.close(err);

  // TODO(BridgeAR): Check if allocating a smaller chunk is better performance
  // wise, similar to the promise based version (less peak memory and chunked
  // stringify operations vs multiple C++/JS boundary crossings).
  const size = context.size = isFileType(stats, S_IFREG) ? stats[8] : 0;

  if (size > kIoMaxLength) {
    err = new ERR_FS_FILE_TOO_LARGE(size);
    return context.close(err);
  }

  try {
    if (size === 0) {
      // TODO(BridgeAR): If an encoding is set, use the StringDecoder to concat
      // the result and reuse the buffer instead of allocating a new one.
      context.buffers = [];
    } else {
      context.buffer = Buffer.allocUnsafeSlow(size);
    }
  } catch (err) {
    return context.close(err);
  }
  context.read();
}


function readFileAfterRead(err, bytesRead) {
  const context = this.context;

  if (err)
    return context.close(err);

  context.pos += bytesRead;

  if (context.pos === context.size || bytesRead === 0) {
    context.close();
  } else {
    if (context.size === 0) {
      // Unknown size, just read until we don't get bytes.
      const buffer = bytesRead === kReadFileUnknownBufferLength ?
        context.buffer : context.buffer.slice(0, bytesRead);
      ArrayPrototypePush(context.buffers, buffer);
    }
    context.read();
  }
}
```


```js

/**
 * Reads file from the specified `fd` (file descriptor).
 * @param {number} fd
 * @param {Buffer | TypedArray | DataView} buffer
 * @param {number} offsetOrOptions
 * @param {number} length
 * @param {number | bigint | null} position
 * @param {(
 *   err?: Error,
 *   bytesRead?: number,
 *   buffer?: Buffer
 *   ) => any} callback
 * @returns {void}
 */
function read(fd, buffer, offsetOrOptions, length, position, callback) {
  fd = getValidatedFd(fd);

  let offset = offsetOrOptions;
  let params = null;
  if (arguments.length <= 4) {
    if (arguments.length === 4) {
      // This is fs.read(fd, buffer, options, callback)
      validateObject(offsetOrOptions, 'options', { nullable: true });
      callback = length;
      params = offsetOrOptions;
    } else if (arguments.length === 3) {
      // This is fs.read(fd, bufferOrParams, callback)
      if (!isArrayBufferView(buffer)) {
        // This is fs.read(fd, params, callback)
        params = buffer;
        ({ buffer = Buffer.alloc(16384) } = params ?? kEmptyObject);
      }
      callback = offsetOrOptions;
    } else {
      // This is fs.read(fd, callback)
      callback = buffer;
      buffer = Buffer.alloc(16384);
    }

    if (params !== undefined) {
      validateObject(params, 'options', { nullable: true });
    }
    ({
      offset = 0,
      length = buffer?.byteLength - offset,
      position = null,
    } = params ?? kEmptyObject);
  }

  validateBuffer(buffer);
  callback = maybeCallback(callback);

  if (offset == null) {
    offset = 0;
  } else {
    validateInteger(offset, 'offset', 0);
  }

  length |= 0;

  if (length === 0) {
    return process.nextTick(function tick() {
      callback(null, 0, buffer);
    });
  }

  if (buffer.byteLength === 0) {
    throw new ERR_INVALID_ARG_VALUE('buffer', buffer,
                                    'is empty and cannot be written');
  }

  validateOffsetLengthRead(offset, length, buffer.byteLength);

  if (position == null)
    position = -1;

  validatePosition(position, 'position');

  function wrapper(err, bytesRead) {
    // Retain a reference to buffer so that it can't be GC'ed too soon.
    callback(err, bytesRead || 0, buffer);
  }

  const req = new FSReqCallback();
  req.oncomplete = wrapper;

  binding.read(fd, buffer, offset, length, position, req);
}

```

```c

/*
 * Wrapper for read(2).
 *
 * bytesRead = fs.read(fd, buffer, offset, length, position)
 *
 * 0 fd        int32. file descriptor
 * 1 buffer    instance of Buffer
 * 2 offset    int64. offset to start reading into inside buffer
 * 3 length    int32. length to read
 * 4 position  int64. file position - -1 for current position
 */
static void Read(const FunctionCallbackInfo<Value>& args) {
  Environment* env = Environment::GetCurrent(args);

  const int argc = args.Length();
  CHECK_GE(argc, 5);

  CHECK(args[0]->IsInt32());
  const int fd = args[0].As<Int32>()->Value();

  CHECK(Buffer::HasInstance(args[1]));
  Local<Object> buffer_obj = args[1].As<Object>();
  char* buffer_data = Buffer::Data(buffer_obj);
  size_t buffer_length = Buffer::Length(buffer_obj);

  CHECK(IsSafeJsInt(args[2]));
  const int64_t off_64 = args[2].As<Integer>()->Value();
  CHECK_GE(off_64, 0);
  CHECK_LT(static_cast<uint64_t>(off_64), buffer_length);
  const size_t off = static_cast<size_t>(off_64);

  CHECK(args[3]->IsInt32());
  const size_t len = static_cast<size_t>(args[3].As<Int32>()->Value());
  CHECK(Buffer::IsWithinBounds(off, len, buffer_length));

  CHECK(IsSafeJsInt(args[4]) || args[4]->IsBigInt());
  const int64_t pos = args[4]->IsNumber() ?
                      args[4].As<Integer>()->Value() :
                      args[4].As<BigInt>()->Int64Value();

  // ...

  char* buf = buffer_data + off;
  uv_buf_t uvbuf = uv_buf_init(buf, len);

  FSReqBase* req_wrap_async = GetReqWrap(args, 5);
  if (req_wrap_async != nullptr) {  // read(fd, buffer, offset, len, pos, req)


    AsyncCall(env, req_wrap_async, args, "read", UTF8, AfterInteger,
              uv_fs_read, fd, &uvbuf, 1, pos);

  } else {  // read(fd, buffer, offset, len, pos, undefined, ctx)
    // ....
  }
}

void AfterInteger(uv_fs_t* req) {
  FSReqBase* req_wrap = FSReqBase::from_req(req);
  FSReqAfterScope after(req_wrap, req);

  int result = static_cast<int>(req->result);
  if (result >= 0 && req_wrap->is_plain_open())
    req_wrap->env()->AddUnmanagedFd(result);

  if (after.Proceed())
    req_wrap->Resolve(Integer::New(req_wrap->env()->isolate(), result));
}

```



## ThreadWork

```cpp

  //
  // ReadFileWork
  //
  class ReadFileWork : public AsyncWrap, public ThreadPoolWork {
   public:
    ReadFileWork(Environment* env, v8::Local<v8::Object> object)
        : AsyncWrap(env, object, AsyncWrap::PROVIDER_FSREADFILEWORK),
          ThreadPoolWork(env, "readfilework") {
      //
    }
    void DoThreadPoolWork() override {
      //
    }
    void AfterThreadPoolWork(int status) override {
      Environment* env = AsyncWrap::env();
      HandleScope handle_scope(env->isolate());
      Context::Scope context_scope(env->context());

      // call the write() cb
      // Local<Value> cb =
      //     object()->GetInternalField(kWriteJSCallback).template As<Value>();
      // MakeCallback(cb.As<Function>(), 0, nullptr);
    }
    // ---- base object
    // Indicates whether this object is expected to use a strong reference during
    // a clean process exit (due to an empty event loop).
    bool IsNotIndicativeOfMemoryLeakAtExit() const override {
      // ReadFileWork runs a work in the libuv thread pool and may still
      // exist when the event loop empties and starts to exit.
      return true;
    }
    // ---- MemoryRetainer
    // ---- async wrap
    const char* MemoryInfoName() const override {
      return "ReadFileWork";
    }

    void MemoryInfo(MemoryTracker* tracker) const override {
      // tracker->TrackField("params", params_);
      // tracker->TrackField("errors", errors_);
    }
  };

  FSReqBase* req_wrap_async = GetReqWrap(args, 3);

  auto read_work = new ReadFileWork(...);


```