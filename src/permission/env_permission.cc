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
  per_process::Debug(DebugCategory::PERMISSION,
                     "!! IsGranted: param: %s\n",
                     std::string(param).c_str());

  bool has_wildcard_in_allow = granted.Lookup("*", false);
  bool has_wildcard_in_deny = denied.Lookup("*", false);

  per_process::Debug(DebugCategory::PERMISSION,
                     "!! IsGranted: wildcard allow, wildcard deny: %d, %d\n",
                     has_wildcard_in_allow,
                     has_wildcard_in_deny);

  if (has_wildcard_in_deny) {
    per_process::Debug(DebugCategory::PERMISSION, "!! IsGranted: DENIED (1)\n");
    return false;
  }

  if (has_wildcard_in_allow) {
    if (denied.Empty()) {
      per_process::Debug(DebugCategory::PERMISSION,
                         "!! IsGranted: GRANTED (2)\n");
      return true;
    }
  } else if (param.length() == 0) {
    per_process::Debug(DebugCategory::PERMISSION, "!! IsGranted: DENIED (3)\n");
    return false;
  }

  std::vector<std::string> tokens = SplitString(std::string(param), ',', true);

  size_t passed_count = 0;

  for (const auto& s : tokens) {
    // TODO(daeyeon): add trimming whitespace as an option to SplitString.
    const std::string token = trim(s);
    per_process::Debug(
        DebugCategory::PERMISSION, "!! IsGranted: [%s] (CHECKING)\n", token);
    if (denied.Lookup(token)) {
      per_process::Debug(DebugCategory::PERMISSION,
                         "!! IsGranted: DENIED (4)\n");
      return false;
    }

    if (!has_wildcard_in_allow && granted.Lookup(token) == false) {
      per_process::Debug(DebugCategory::PERMISSION,
                         "!! IsGranted: DENIED (5)\n");
      return false;
    }
    passed_count++;
  }

  CHECK(passed_count == tokens.size());

  per_process::Debug(DebugCategory::PERMISSION, "!! IsGranted: GRANTED (2)\n");

  return true;
}

void EnvPermission::Apply(const std::string& allow, PermissionScope scope) {
  static const char delimiter = ',';

  if (scope == PermissionScope::kEnvVars) {
    for (const auto& s : SplitString(allow, delimiter, true)) {
      // TODO(daeyeon): add trimming whitespace as an option to SplitString.
      const std::string token = trim(s);
      if (token.front() == '-') {
        per_process::Debug(
            DebugCategory::PERMISSION, "!! EnvPermission::Apply: %s\n", token);
        denied_envvars_.Insert(token.substr(1));
      } else {
        per_process::Debug(
            DebugCategory::PERMISSION, "!! EnvPermission::Apply: %s\n", token);
        granted_envvars_.Insert(token);
      }
    }
  }
}

bool EnvPermission::is_granted(PermissionScope scope,
                               const std::string_view& param) {
  // TODO: how to handle NODE_OPTIONS?
  // https://github.com/Samsung/lwnode/blob/76b0cd898007dc551045660ddcb9dec79b2607df/src/api/utils/logger/flags.cc
  if (scope == PermissionScope::kEnvVars) {
    return IsGranted(granted_envvars_, denied_envvars_, param);
  }

  return false;
}

}  // namespace permission
}  // namespace node
