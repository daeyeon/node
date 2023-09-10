
```js
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
---------------------------------------------------------------------


template <typename T, bool kIsWeak>
BaseObjectPtrImpl<T, kIsWeak>::BaseObjectPtrImpl(T* target)
  : BaseObjectPtrImpl() {
  if (target == nullptr) return;
  if constexpr (kIsWeak) {
    data_.pointer_data = target->pointer_data();
    CHECK_NOT_NULL(pointer_data());
    pointer_data()->weak_ptr_count++;
  } else {
    data_.target = target;
    CHECK_NOT_NULL(pointer_data());
    get()->increase_refcount();
  }
}

void BaseObject::decrease_refcount() {
  CHECK(has_pointer_data());
  PointerData* metadata = pointer_data();
  CHECK_GT(metadata->strong_ptr_count, 0);
  unsigned int new_refcount = --metadata->strong_ptr_count;
  if (new_refcount == 0) {
    if (metadata->is_detached) {
      OnGCCollect();  // <-- Detached 가 되면 강제로 불려진다.refcount 가 0일때 강제로 부름
    } else if (metadata->wants_weak_jsobj && !persistent_handle_.IsEmpty()) {
      MakeWeak();
    }
  }
}

----------------------------------------------------------------------

FSReqAfterScope::FSReqAfterScope(FSReqBase* wrap, uv_fs_t* req)
    : wrap_(wrap),
      req_(req),
      handle_scope_(wrap->env()->isolate()),
      context_scope_(wrap->env()->context()) {
  CHECK_EQ(wrap_->req(), req);
}

FSReqAfterScope::~FSReqAfterScope() {
  Clear();
}

void FSReqAfterScope::Clear() {
  if (!wrap_) return;

  uv_fs_req_cleanup(wrap_->req());
  wrap_->Detach();  // BaseObjectPtr<FSReqBase> wrap_;
  wrap_.reset();
}

static void AfterInteger2(uv_fs_t* req) {
  FSReqBase* req_wrap = FSReqBase::from_req(req);
  FSReqAfterScope after(req_wrap, req);  // << --- FSReqAfterScope

  int result = static_cast<int>(req->result);
  if (result >= 0 && req_wrap->is_plain_open())
    req_wrap->env()->AddUnmanagedFd(result); // <-- add tracing fd

  if (after.Proceed())  // <-- check req_->result < 0 and call js back
    req_wrap->Resolve(Integer::New(req_wrap->env()->isolate(), result));
}

bool FSReqAfterScope::Proceed() {
  if (!wrap_->env()->can_call_into_js()) {
    return false;
  }

  if (req_->result < 0) {
    Reject(req_);
    return false;
  }
  return true;
}

----------------------------------------------------------------------

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



class ReadFileContext {
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
    req.context = this; // <- context 가 이걸로 변경

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


// err, bytesRead
// context.size: 크기 설정해둬야함.
function readFileAfterRead(err, bytesRead) {
  const context = this.context;

  if (err)
    return context.close(err);

  context.pos += bytesRead;

  if (context.pos === context.size || bytesRead === 0) {
    context.close(); // <--
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

// err, 결국 이 함수와 바인딩하면됨.
// context.callback 은 뭔가?
//
// class ReadFileContext {
//   constructor(callback, encoding) {
//     ...
//     this.size = 0; //  context.size = isFileType(stats, S_IFREG) ? stats[8] : 0;
//     this.callback = callback;
//     this.pos = 0;
/*

  // Stat 체크 맥스
  if (size > kIoMaxLength) {
    err = new ERR_FS_FILE_TOO_LARGE(size);
    return context.close(err);
  }

*/
function readFileAfterClose(err) {
  const context = this.context;
  const callback = context.callback;
  let buffer = null;

  if (context.err || err)
    return callback(aggregateTwoErrors(err, context.err));

  try {
    if (context.size === 0)
      buffer = Buffer.concat(context.buffers, context.pos);
    else if (context.pos < context.size)
      buffer = context.buffer.slice(0, context.pos);
    else
      buffer = context.buffer;

    if (context.encoding)
      buffer = buffer.toString(context.encoding);
  } catch (err) {
    return callback(err);
  }

  callback(null, buffer);
}

```
