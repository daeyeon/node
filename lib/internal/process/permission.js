'use strict';

const { ObjectFreeze, RegExpPrototypeExec, StringPrototypeStartsWith } =
  primordials;

const permission = internalBinding('permission');
const { validateString } = require('internal/validators');
const { isAbsolute, resolve } = require('path');
const {
  codes: { ERR_INVALID_ARG_VALUE },
} = require('internal/errors');

let experimentalPermission;

const envScopeReferenceRegExp = /^[a-zA-Z_][a-zA-Z0-9_]*$/;
function validateEnvHasReference(value, name) {
  if (!RegExpPrototypeExec(envScopeReferenceRegExp, value)) {
    throw new ERR_INVALID_ARG_VALUE(
      name,
      value,
      'must consist of letters, digits, and underscore, starting with a letter or underscore'
    );
  }
}

module.exports = ObjectFreeze({
  __proto__: null,
  isEnabled() {
    if (experimentalPermission === undefined) {
      const { getOptionValue } = require('internal/options');
      experimentalPermission = getOptionValue('--experimental-permission');
    }
    return experimentalPermission;
  },
  has(scope, reference) {
    validateString(scope, 'scope');
    if (reference != null) {
      // TODO: add support for WHATWG URLs and Uint8Arrays.
      validateString(reference, 'reference');
      if (StringPrototypeStartsWith(scope, 'fs')) {
        if (!isAbsolute(reference)) {
          reference = resolve(reference);
        }
      } else if (StringPrototypeStartsWith(scope, 'env')) {
        validateEnvHasReference(reference, 'reference');
      }
    }

    return permission.has(scope, reference);
  },
});
