export default [
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: 2020,
      sourceType: "module",
    },
    rules: {
      "quotes": ["error", "double", { "allowTemplateLiterals": true }],
      "indent": ["error", 2],
      "max-len": ["warn", { "code": 120 }],
      "eol-last": ["error", "always"],
      "semi": ["error", "always"],
      "no-unused-vars": ["warn"],
      "no-console": ["off"],
    },
  },
];
