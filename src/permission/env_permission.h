#ifndef SRC_PERMISSION_ENV_PERMISSION_H_
#define SRC_PERMISSION_ENV_PERMISSION_H_

#if defined(NODE_WANT_INTERNALS) && NODE_WANT_INTERNALS

#include <string>
#include "permission/permission_util.h"

namespace node {

namespace permission {

class EnvPermission final : public PermissionBase {
 public:
  void Apply(const std::string& allow, PermissionScope scope) override;
  bool is_granted(PermissionScope scope,
                  const std::string_view& param = "") override;

 private:
  SearchTree denied_envvars_;
  SearchTree granted_envvars_;
};

}  // namespace permission

}  // namespace node

#endif  // defined(NODE_WANT_INTERNALS) && NODE_WANT_INTERNALS
#endif  // SRC_PERMISSION_ENV_PERMISSION_H_
