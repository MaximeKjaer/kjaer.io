# SCSS Style Guide

This is an adapted copy of [Dropbox's CSS Style Guide](https://github.com/dropbox/css-style-guide) (released under [Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0)).

I've removed all rules that I don't want to abide by in this project (most notably, BEM and everything that follows).

## General

### Don’ts

- Avoid using HTML tags in CSS class or ID selectors
  - E.g. Prefer `.post {}` over `div.post {}`
- Don't use ids in selectors
  - `#header` is overly specific compared to, for example `.header` and is much harder to override
  - Read more about the headaches associated with IDs in CSS [here](http://csswizardry.com/2011/09/when-using-ids-can-be-a-pain-in-the-class/).
- Don’t nest more than 3 levels deep (4 if you *really* must)
  - Nesting selectors increases specificity, meaning that overriding any CSS set therein needs to be targeted with an even more specific selector. This quickly becomes a significant maintenance issue.
- Don't `!important`
  - Ever.
  - If you must, leave a comment, and prioritise resolving specificity issues before resorting to `!important`.
  - `!important` greatly increases the power of a CSS rule, making it extremely tough to override in the future. It’s only possible to override with another `!important` rule later in the cascade.
- Don’t use `margin-top`.
  - Vertical margins [collapse](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Box_Model/Mastering_margin_collapsing). Always prefer `padding-top` or`margin-bottom` on preceding elements
- Avoid shorthand properties (unless you really need them)
  - It can be tempting to use, for instance, `background: #fff` instead of `background-color: #fff`, but doing so overrides other values encapsulated by the shorthand property. (In this case, `background-image` and its associative properties are set to “none.”
  - This applies to all properties with a shorthand: border, margin, padding, font, etc.

### Spacing

- Tabs for indenting code
- Put spaces after `:` in property declarations
  - E.g. `color: red;` instead of `color:red;`
- Put spaces before `{` in rule declarations
  - E.g. `.o-modal {` instead of `.o-modal{`
- Write your CSS one line per rule
- Add a line break after `}` closing rule declarations if there are other declarations after it.
- Place closing braces `}` on a new line
- Add a new line at the end of .scss files
- Trim excess whitespace

### Formatting

- All selectors are lower case, hyphen separated aka “spinal case” eg. `.my-class-name`
- Always prefer Sass’s double-slash `//` commenting, even for block comments
- Avoid specifying units for zero values, e.g. `margin: 0;` instead of `margin: 0px;`
- Always add a semicolon to the end of a property/value rule
- Always use single quotes (`'...'`) for strings
- Use leading zeros for decimal values `opacity: 0.4;` instead of `opacity: .4;`
- Put spaces before and after child selector `div > span` instead of `div>span`

----------

## Sass Specifics
### Internal order of a .scss file

1. Imports
2. Variables
3. Base Styles

Example:

```scss
//------------------------------
// Modal
//------------------------------

@import "../constants";
@import "../helpers";

$DBmodal-namespace: "c-modal" !default;
$DBmodal-padding: 32px;

$DBmodal-background: #fff !default;
$DBmodal-background-alt: color(gray, x-light) !default;

.o-modal { ... }
```

### Variables

*I'm not using local variables in this project, but here's how I'd like them to look if I add some one day.*

- Define all variables at the top of the file after the imports
- Namespace local variables with the filename (SASS has no doc level scope)
  - eg `business-contact.scss` →`$business-contact-font_size: 14px;`

### Color

- Use the defined color constants
- Lowercase all hex values `#fffff`
- Limit alpha values to a maximum of two decimal places. Always use a leading zero.

Example:

```scss
// Bad
.c-link {
  color: #007ee5;
  border-color: #FFF;
  background-color: rgba(#FFF, .0625);
}

// Good
.c-link {
  color: $blue;
  border-color: #fff;
  background-color: rgba(#fff, 0.06);
}
```

----------

## Rule Ordering

Properties and nested declarations should appear in the following order, with line breaks between groups:

1. Any `@` SCSS rules
2. Layout and box-model properties
  - margin, padding, box-sizing, overflow, position, display, width/height, etc.
3. Typographic properties
  - E.g. font-*, line-height, letter-spacing, text-*, etc.
4. Stylistic properties
  - color, background-*, animation, border, etc.
5. UI properties
  - appearance, cursor, user-select, pointer-events, etc.
6. Pseudo-elements
  - ::after, ::before, ::selection, etc.
7. Pseudo-selectors
  - :hover, :focus, :active, etc.
8. Modifier classes
9. Nested elements

Here’s a comprehensive example:

```scss
.c-btn {
    @extend %link--plain;

    display: inline-block;
    padding: 6px 12px;

    text-align: center;
    font-weight: 600;

    background-color: color(blue);
    border-radius: 3px;
    color: white;

    &::before {
        content: '';
    }

    &:focus, &:hover {
        box-shadow: 0 0 0 1px color(blue, .3);
    }

    &--big {
        padding: 12px 24px;
    }

    > .c-icon {
        margin-right: 6px;
    }
}
```


----------

## Media Queries

Media queries should be within the CSS selector as per SMACSS

```scss
.selector {
      float: left;

      @media only screen and (max-width: 767px) {
        float: none;
      }
}
```

Create variables for frequently used breakpoints.
