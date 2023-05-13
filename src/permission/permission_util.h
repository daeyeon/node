#ifndef SRC_PERMISSION_PERMISSION_UTIL_H_
#define SRC_PERMISSION_PERMISSION_UTIL_H_

#if defined(NODE_WANT_INTERNALS) && NODE_WANT_INTERNALS

#include <string>
#include "permission/fs_permission.h"

namespace node {

namespace permission {

class SearchTree {
 public:
  bool Insert(const std::string& s);
  bool Lookup(const std::string_view& s, bool when_empty_return);
  bool Lookup(const std::string& s);
  bool Empty() { return tree_.Empty(); }

  FSPermission::RadixTree::Node* GetRoot() { return tree_.GetRoot(); }
  FSPermission::RadixTree::Node* NextNode(
      const FSPermission::RadixTree::Node* node,
      const std::string& path,
      unsigned int idx);

 private:
  // TODO(daeyeon): Refactor the code for handling paths in FSPermission and
  // make FSPermission::RadixTree reusable with other permissions.
  FSPermission::RadixTree tree_;
};

}  // namespace permission

}  // namespace node
#endif  // defined(NODE_WANT_INTERNALS) && NODE_WANT_INTERNALS
#endif  // SRC_CRYPTO_CRYPTO_UTIL_H_
