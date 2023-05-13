#include "permission/env_permission.h"
#include "debug_utils-inl.h"
#include "debug_utils.h"
#include "util.h"

namespace node {

static std::string trim(const std::string& str) {
  static const std::string whitespace = " \n\r\t";

  size_t first = str.find_first_not_of(whitespace);
  if (first == std::string::npos) return "";

  size_t last = str.find_last_not_of(whitespace);
  return str.substr(first, last - first + 1);
}

namespace permission {

static inline bool IsGranted(SearchTree& granted,
                             SearchTree& denied,
                             const std::string_view& param) {
  bool has_wildcard_in_allow = granted.Lookup("*");
  bool has_wildcard_in_deny = denied.Lookup("*");

  if (has_wildcard_in_deny) {
    return false;
  }

  if (has_wildcard_in_allow) {
    if (denied.Empty()) {
      return true;
    }
  } else if (param.empty()) {
    return false;
  }

  if (denied.Lookup(param)) {
    return false;
  }

  if (!has_wildcard_in_allow && !granted.Lookup(param)) {
    return false;
  }

  return true;
}

void EnvPermission::Apply(const std::string& allow, PermissionScope scope) {
  if (scope == PermissionScope::kEnvVars) {
    for (const auto& s : SplitString(allow, ',', true)) {
      // TODO(daeyeon): add trimming whitespace as an option to SplitString.
      const std::string token = trim(s);
      if (token.front() == '-') {
        denied_envvars_.Insert(token.substr(1));
      } else {
        granted_envvars_.Insert(token);
      }
    }
  }
}

bool EnvPermission::is_granted(PermissionScope scope,
                               const std::string_view& param) {
  if (scope == PermissionScope::kEnvVars) {
    return IsGranted(granted_envvars_, denied_envvars_, param);
  }

  return false;
}

}  // namespace permission
}  // namespace node
