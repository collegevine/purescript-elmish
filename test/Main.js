import jsdom from 'global-jsdom';

// This needs to run before React, which is why it’s being run globally in the
// FFI. See https://enzymejs.github.io/enzyme/docs/guides/jsdom.html for more
// info.
jsdom()

export var _configureJsDomViaFfi = null;
