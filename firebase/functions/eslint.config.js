const {FlatCompat} = require("@eslint/eslintrc");
const js = require("@eslint/js");
const globals = require("globals");
const {builtinRules} = require("eslint/use-at-your-own-risk");

const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
});

/**
 * Drop rules ESLint 10 no longer ships.
 * @param {Array<object>} configs Flat config objects.
 * @return {Array<object>} Configs with unknown core rules removed.
 */
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

module.exports = (async () => {
  const {default: jsdoc} = await import("eslint-plugin-jsdoc");
  const {default: stylistic} = await import("@stylistic/eslint-plugin");

  return [
    ...withoutRemovedRules(
        compat.extends("eslint:recommended", "google"),
    ),
    {
      plugins: {
        "@stylistic": stylistic,
        jsdoc,
      },
      languageOptions: {
        ecmaVersion: 2022,
        sourceType: "commonjs",
        globals: {
          ...globals.node,
        },
      },
      settings: {
        jsdoc: {
          // eslint-config-google valid-jsdoc prefer: {returns: "return"}
          tagNamePreference: {
            returns: "return",
          },
        },
      },
      rules: {
        "no-restricted-globals": ["error", "name", "length"],
        "prefer-arrow-callback": "error",
        "quotes": ["error", "double", {"allowTemplateLiterals": true}],
        "no-inner-declarations": "error",
        "@stylistic/no-extra-semi": "error",
        "jsdoc/require-jsdoc": ["error", {
          require: {
            FunctionDeclaration: true,
            MethodDefinition: true,
            ClassDeclaration: true,
          },
        }],
        "jsdoc/check-param-names": "error",
        "jsdoc/check-syntax": "error",
        "jsdoc/check-tag-names": "error",
        "jsdoc/valid-types": "error",
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
})();
