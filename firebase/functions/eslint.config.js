const {FlatCompat} = require("@eslint/eslintrc");
const js = require("@eslint/js");
const globals = require("globals");
const {builtinRules} = require("eslint/use-at-your-own-risk");

const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
});

// eslint-config-google still enables rules ESLint 10 removed.
function withoutRemovedRules(configs) {
  return configs.map((config) => {
    if (!config.rules) {
      return config;
    }
    const rules = {};
    for (const [name, value] of Object.entries(config.rules)) {
      const pluginRule = name.includes("/");
      if (pluginRule || builtinRules.has(name)) {
        rules[name] = value;
      }
    }
    return {...config, rules};
  });
}

module.exports = [
  ...withoutRemovedRules(
      compat.extends("eslint:recommended", "google"),
  ),
  {
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "commonjs",
      globals: {
        ...globals.node,
      },
    },
    rules: {
      "no-restricted-globals": ["error", "name", "length"],
      "prefer-arrow-callback": "error",
      "quotes": ["error", "double", {"allowTemplateLiterals": true}],
    },
  },
  {
    files: ["**/*.spec.*"],
    languageOptions: {
      globals: {
        ...globals.mocha,
      },
    },
  },
];
