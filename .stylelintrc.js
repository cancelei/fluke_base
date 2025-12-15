'use strict';

module.exports = {
  plugins: ['stylelint-scss'],
  extends: ['stylelint-config-recommended-scss'],
  reportNeedlessDisables: true,
  reportInvalidScopeDisables: true,
  reportDescriptionlessDisables: true,
  rules: {
    'no-descending-specificity': null,
    'string-no-newline': true,
    'color-no-invalid-hex': true,
    'comment-whitespace-inside': 'always',
    'declaration-block-no-duplicate-custom-properties': true,
    'declaration-block-no-duplicate-properties': true,
    'no-invalid-double-slash-comments': true,
    'no-duplicate-at-import-rules': true,
    'no-invalid-position-at-import-rule': null,
    'length-zero-no-unit': true,
    'scss/at-rule-no-unknown': [
      true,
      {
        ignoreAtRules: [
          'plugin',
          'tailwind',
          'apply',
          'layer',
          'variants',
          'responsive',
          'screen'
        ]
      }
    ],
    'property-no-unknown': [
      true,
      {
        ignoreProperties: [
          'ring',
          'ring-color',
          'ring-offset',
          'ring-offset-color'
        ]
      }
    ]
  }
};
