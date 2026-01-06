/**
 * Taggle - dependency-less tagging library
 * @author Sean Coker <hello@sean.is>
 * @version 1.15.0 (modified)
 * @license MIT
 */

/////////////////////
// Default options //
/////////////////////

const BACKSPACE = 8;
const DELETE = 46;
const COMMA = 188;
const TAB = 9;
const ENTER = 13;

const DEFAULTS = {
  /**
   * Class added to the container div when focused
   * @type {String}
   */
  containerFocusClass: 'active',

  /**
   * Spaces will be removed from the tags by default
   * @type {Boolean}
   */
  trimTags: true,

  /**
   * Limit the number of tags that can be added
   * @type {Number}
   */
  maxTags: null,

  /**
   * Placeholder string to be placed in an empty taggle field
   * @type {String}
   */
  placeholder: 'Enter tags...',

  /**
   * Keycodes that will add a tag
   * @type {Array}
   */
  submitKeys: [COMMA, TAB, ENTER],

  /**
   * Preserve case of tags being added ie
   * "tag" is different than "Tag"
   * @type {Boolean}
   */
  preserveCase: false,

  /**
   * Function hook called when a tag is added
   * @param  {Event} event Event triggered when tag was added
   * @param  {String} tag The tag added
   */
  onTagAdd: () => {},

  /**
   * Function hook called when a tag is removed
   * @param  {Event} event Event triggered when tag was removed
   * @param  {String} tag The tag removed
   */
  onTagRemove: () => {}
};

//////////////////////
// Helper functions //
//////////////////////
function _clamp(val, min, max) {
  return Math.min(Math.max(val, min), max);
}

/**
 * Taggle ES6 Class - Modern tagging library
 */
class Taggle {
  /**
   * Constructor
   * @param {Mixed} el ID of an element or the actual element
   * @param {Object} options
   */
  constructor(el, options) {
    this.settings = Object.assign({}, DEFAULTS, options);
    this.measurements = {
      container: {
        rect: null,
        style: null,
        padding: null
      }
    };
    this.container = el;
    this.tag = {
      values: [],
      elements: []
    };
    this.inputContainer = options.inputContainer;
    this.input = document.createElement('input');
    this.sizer = document.createElement('div');
    this.pasting = false;
    this.placeholder = null;

    if (this.settings.placeholder) {
      this.placeholder = document.createElement('span');
    }

    this._backspacePressed = false;
    this._inputPosition = 0;
    this._setMeasurements();
    this._setupTextarea();
    this._attachEvents();
  }

  /**
   * Gets all the layout measurements up front
   */
  _setMeasurements() {
    this.measurements.container.rect = this.container.getBoundingClientRect();
    const style = window.getComputedStyle(this.container);
    this.measurements.container.style = style;

    const lpad = parseInt(style.paddingLeft, 10);
    const rpad = parseInt(style.paddingRight, 10);
    const lborder = parseInt(style.borderLeftWidth, 10);
    const rborder = parseInt(style.borderRightWidth, 10);

    this.measurements.container.padding = lpad + rpad + lborder + rborder;
  }

  /**
   * Setup the div container for tags to be entered
   */
  _setupTextarea() {
    this.input.type = 'text';
    // Make sure no left/right padding messes with the input sizing
    this.input.style.paddingLeft = 0;
    this.input.style.paddingRight = 0;
    this.input.className = 'taggle_input';
    this.input.tabIndex = 1;
    this.sizer.className = 'taggle_sizer';

    [...this.container.children].filter(child => child.tagName === 'TAG-OPTION').forEach(tagOption => {
      this.tag.values.push(tagOption.value);
      this.tag.elements.push(tagOption);
      this._inputPosition = _clamp(this._inputPosition + 1, 0, this.tag.values.length);
    });


    if (this.placeholder) {
      this._hidePlaceholder();
      this.placeholder.classList.add('taggle_placeholder');
      this.container.appendChild(this.placeholder);
      this.placeholder.textContent = this.settings.placeholder;

      if (!this.tag.values.length) {
        this._showPlaceholder();
      }
    }


    const div = document.createElement('div');
    div.appendChild(this.input);
    div.appendChild(this.sizer);
    this.inputContainer.appendChild(div);
    const fontSize = window.getComputedStyle(this.input).fontSize;
    this.sizer.style.fontSize = fontSize;
  }

  /**
   * Attaches neccessary events
   */
  _attachEvents() {
    if (this._eventsAttached) {
      return false;
    }
    this._eventsAttached = true;

    this._handleContainerClick = () => this.input.focus();
    this.container.addEventListener('click', this._handleContainerClick);

    this._handleFocus = this._setFocusStateForContainer.bind(this);
    this._handleBlur = this._blurEvent.bind(this);
    this._handleKeydown = this._keydownEvents.bind(this);
    this._handleKeyup = this._keyupEvents.bind(this);

    this.input.addEventListener('focus', this._handleFocus);
    this.input.addEventListener('blur', this._handleBlur);
    this.input.addEventListener('keydown', this._handleKeydown);
    this.input.addEventListener('keyup', this._handleKeyup);

    return true;
  }

  _detachEvents() {
    if (!this._eventsAttached) {
      return false;
    }
    this._eventsAttached = false;

    this.container.removeEventListener('click', this._handleContainerClick);
    this.input.removeEventListener('focus', this._handleFocus);
    this.input.removeEventListener('blur', this._handleBlur);
    this.input.removeEventListener('keydown', this._handleKeydown);
    this.input.removeEventListener('keyup', this._handleKeyup);

    return true;
  }

  /**
   * Returns whether or not the specified tag text can be added
   * @param {Event} e event causing the potentially added tag
   * @param {String} text tag value
   * @return {Boolean}
   */
  _canAdd(e, text) {
    if (!text) {
      return false;
    }
    const limit = this.settings.maxTags;
    if (limit !== null && limit <= this.getTagValues().length) {
      return false;
    }

    // Check for duplicates
    return this.tag.values.indexOf(text) === -1;
  }

  /**
   * Appends tag with its corresponding input to the list
   * @param {Event} e
   * @param {String} text
   * @param {Number} index
   */
  _add(e, text, index) {
    let values = text || '';
    const delimiter = ',';

    if (typeof text !== 'string') {
      values = this.input.value;

      if (this.settings.trimTags) {
        if (values[0] === delimiter) {
          values = values.replace(delimiter, '');
        }
        values = values.trim();
      }
    }

    values.split(delimiter).map(val => {
      if (this.settings.trimTags) {
        val = val.trim();
      }
      return this._formatTag(val);
    }).forEach(val => {
      if (!this._canAdd(e, val)) {
        return;
      }

      const currentTagLength = this.tag.values.length;
      const tagIndex = _clamp(index || currentTagLength, 0, currentTagLength);
      const tagOption = this._createTag(val, tagIndex);
      this.container.append(tagOption);

      val = this.tag.values[tagIndex];

      this.settings.onTagAdd(e, val);

      this.input.value = '';
      this._setMeasurements();
      this._setInputWidth();
      this._setFocusStateForContainer();
    });
  }

  /**
   * Removes last tag if it has already been probed
   * @param {Event} e
   */
  _checkPrevOrNextTag(e) {
    const taggles = this.container.querySelectorAll('tag-option');
    const prevTagIndex = _clamp(this._inputPosition - 1, 0, taggles.length - 1);
    const nextTagIndex = _clamp(this._inputPosition, 0, taggles.length - 1);
    let index = prevTagIndex;

    if (e.keyCode === DELETE) {
      index = nextTagIndex;
    }

    const targetTaggle = taggles[index];
    const hotClass = 'taggle_hot';
    const isDeleteOrBackspace = [BACKSPACE, DELETE].includes(e.keyCode);

    // prevent holding backspace from deleting all tags
    if (this.input.value === '' && isDeleteOrBackspace && !this._backspacePressed) {
      if (targetTaggle.classList.contains(hotClass)) {
        this._backspacePressed = true;
        this._remove(targetTaggle, e);
        this._setMeasurements();
        this._setInputWidth();
        this._setFocusStateForContainer();
      }
      else {
        targetTaggle.classList.add(hotClass);
      }
    }
    else if (targetTaggle.classList.contains(hotClass)) {
      targetTaggle.classList.remove(hotClass);
    }
  }

  /**
   * Setter for the hidden input.
   * @param {Number} width
   */
  _setInputWidth() {
    const width = this.sizer.getBoundingClientRect().width;
    const max = this.measurements.container.rect.width - this.measurements.container.padding;
    const size = parseInt(this.sizer.style.fontSize, 10);

    // 1.5 just seems to be a good multiplier here
    const newWidth = Math.round(_clamp(width + (size * 1.5), 10, max));

    this.input.style.width = `${newWidth}px`;
  }

  /**
   * Handles focus state of div container.
   */
  _setFocusStateForContainer() {
    this._setMeasurements();
    this._setInputWidth();

    if (!this.container.classList.contains(this.settings.containerFocusClass)) {
      this.container.classList.add(this.settings.containerFocusClass);
    }

    this._hidePlaceholder();
  }

  /**
   * Runs all the events that need to happen on a blur
   * @param {Event} e
   */
  _blurEvent(e) {
    if (this.container.classList.contains(this.settings.containerFocusClass)) {
      this.container.classList.remove(this.settings.containerFocusClass);
    }

    if (!this.tag.values.length && !this.input.value) {
      this._showPlaceholder();
    }
  }

  /**
   * Runs all the events that need to run on keydown
   * @param {Event} e
   */
  _keydownEvents(e) {
    const key = e.keyCode;
    this.pasting = false;

    this._setInputWidth();

    if (key === 86 && e.metaKey) {
      this.pasting = true;
    }

    if (this.settings.submitKeys.includes(key) && this.input.value !== '') {
      this._confirmValidTagEvent(e);
      return;
    }

    if (this.tag.values.length) {
      this._checkPrevOrNextTag(e);
    }
  }

  /**
   * Runs all the events that need to run on keyup
   * @param {Event} e
   */
  _keyupEvents(e) {
    this._backspacePressed = false;

    this.sizer.textContent = this.input.value;

    // If we break to a new line because the text is too long
    // and decide to delete everything, we should resize the input
    // so it falls back inline
    if (!this.input.value) {
      this._setInputWidth();
    }

    if (this.pasting && this.input.value !== '') {
      this._add(e);
      this.pasting = false;
    }
  }

  /**
   * Confirms the inputted value to be converted to a tag
   * @param {Event} e
   */
  _confirmValidTagEvent(e) {
    // prevents from jumping out of textarea
    e.preventDefault();

    this._add(e, null, this._inputPosition);
  }

  _createTag(text, index) {
    const tagOption = document.createElement('tag-option');

    text = this._formatTag(text);
    tagOption.textContent = text;
    tagOption.setAttribute('value', text);

    this.tag.values.splice(index, 0, text);
    this.tag.elements.splice(index, 0, tagOption);
    this._inputPosition = _clamp(this._inputPosition + 1, 0, this.tag.values.length);

    return tagOption;
  }

  _showPlaceholder() {
    if (this.placeholder) {
      this.placeholder.style.opacity = 1;
      this.placeholder.setAttribute('aria-hidden', 'false');
    }
  }

  _hidePlaceholder() {
    if (this.placeholder) {
      this.placeholder.style.opacity = 0;
      this.placeholder.setAttribute('aria-hidden', 'true');
    }
  }

  /**
   * Removes tag from the tags collection
   * @param {HTMLElement} tagOption List item to remove
   * @param {Event} e
   */
  _remove(tagOption, e) {
    const index = this.tag.elements.indexOf(tagOption);
    if (index === -1) return;

    const text = this.tag.values[index];

    tagOption.remove();
    this.tag.elements.splice(index, 1);
    this.tag.values.splice(index, 1);
    this.settings.onTagRemove(e, text);

    if (index < this._inputPosition) {
      this._inputPosition = _clamp(this._inputPosition - 1, 0, this.tag.values.length);
    }

    this._setFocusStateForContainer();
  }

  /**
   * Format the text for a tag
   * @param {String} text Tag text
   * @return {String}
   */
  _formatTag(text) {
    return this.settings.preserveCase ? text : text.toLowerCase();
  }

  // @todo
  // @deprecated use getTags().values
  getTagValues() {
    return [...this.tag.values];
  }

  getInput() {
    return this.input;
  }

  add(text, index) {
    const isArr = Array.isArray(text);

    if (isArr) {
      text.forEach((tag, i) => {
        if (typeof tag === 'string') {
          this._add(null, tag, index ? index + i : index);
        }
      });
    }
    else {
      this._add(null, text, index);
    }

    return this;
  }

  remove(text) {
    const index = this.tag.values.indexOf(text);
    if (index > -1) {
      this._remove(this.tag.elements[index]);
    }
    return this;
  }

  removeAll() {
    [...this.tag.elements].forEach(element => this._remove(element));
    this._showPlaceholder();
    return this;
  }

  _setDisabledState(disabled) {
    const elements = [
      ...this.container.querySelectorAll('button'),
      ...this.container.querySelectorAll('input')
    ];

    elements.forEach((el) => {
      if (disabled) {
        el.setAttribute('disabled', '');
      } else {
        el.removeAttribute('disabled');
      }
    });

    return this;
  }

  enable() {
    return this._setDisabledState(false);
  }

  disable() {
    return this._setDisabledState(true);
  }

  destroy() {
    this._detachEvents();
  }
}

/**
 * Copyright (c) 2016 Denis Taran
 *
 * Homepage: https://smartscheduling.com/en/documentation/autocomplete
 * Source: https://github.com/denis-taran/autocomplete
 *
 * MIT License
 */
function autocomplete(settings) {
    // just an alias to minimize JS file size
    var doc = document;
    var container = settings.container || doc.createElement('div');
    var preventSubmit = settings.preventSubmit || 0 /* Never */;
    container.id = container.id || 'autocomplete-' + uid();
    var containerStyle = container.style;
    var debounceWaitMs = settings.debounceWaitMs || 0;
    var disableAutoSelect = settings.disableAutoSelect || false;
    var customContainerParent = container.parentElement;
    var items = [];
    var inputValue = '';
    var minLen = 2;
    var showOnFocus = settings.showOnFocus;
    var selected;
    var fetchCounter = 0;
    var debounceTimer;
    var destroyed = false;
    // Fixes #104: autocomplete selection is broken on Firefox for Android
    var suppressAutocomplete = false;
    if (settings.minLength !== undefined) {
        minLen = settings.minLength;
    }
    if (!settings.input) {
        throw new Error('input undefined');
    }
    var input = settings.input;
    container.className = [container.className, 'autocomplete', settings.className || ''].join(' ').trim();
    container.setAttribute('role', 'listbox');
    input.setAttribute('role', 'combobox');
    input.setAttribute('aria-expanded', 'false');
    input.setAttribute('aria-autocomplete', 'list');
    input.setAttribute('aria-controls', container.id);
    input.setAttribute('aria-owns', container.id);
    input.setAttribute('aria-activedescendant', '');
    input.setAttribute('aria-haspopup', 'listbox');
    // IOS implementation for fixed positioning has many bugs, so we will use absolute positioning
    containerStyle.position = 'absolute';
    /**
     * Generate a very complex textual ID that greatly reduces the chance of a collision with another ID or text.
     */
    function uid() {
        return Date.now().toString(36) + Math.random().toString(36).substring(2);
    }
    /**
     * Detach the container from DOM
     */
    function detach() {
        var parent = container.parentNode;
        if (parent) {
            parent.removeChild(container);
        }
    }
    /**
     * Clear debouncing timer if assigned
     */
    function clearDebounceTimer() {
        if (debounceTimer) {
            window.clearTimeout(debounceTimer);
        }
    }
    /**
     * Attach the container to DOM
     */
    function attach() {
        if (!container.parentNode) {
            (customContainerParent || doc.body).appendChild(container);
        }
    }
    /**
     * Check if container for autocomplete is displayed
     */
    function containerDisplayed() {
        return !!container.parentNode;
    }
    /**
     * Clear autocomplete state and hide container
     */
    function clear() {
        // prevent the update call if there are pending AJAX requests
        fetchCounter++;
        items = [];
        inputValue = '';
        selected = undefined;
        input.setAttribute('aria-activedescendant', '');
        input.setAttribute('aria-expanded', 'false');
        detach();
    }
    /**
     * Update autocomplete position
     */
    function updatePosition() {
        if (!containerDisplayed()) {
            return;
        }
        input.setAttribute('aria-expanded', 'true');
        containerStyle.height = 'auto';
        containerStyle.width = input.offsetWidth + 'px';
        var maxHeight = 0;
        var inputRect;
        function calc() {
            var docEl = doc.documentElement;
            var clientTop = docEl.clientTop || doc.body.clientTop || 0;
            var clientLeft = docEl.clientLeft || doc.body.clientLeft || 0;
            var scrollTop = window.pageYOffset || docEl.scrollTop;
            var scrollLeft = window.pageXOffset || docEl.scrollLeft;
            inputRect = input.getBoundingClientRect();
            var top = inputRect.top + input.offsetHeight + scrollTop - clientTop;
            var left = inputRect.left + scrollLeft - clientLeft;
            containerStyle.top = top + 'px';
            containerStyle.left = left + 'px';
            maxHeight = window.innerHeight - (inputRect.top + input.offsetHeight);
            if (maxHeight < 0) {
                maxHeight = 0;
            }
            containerStyle.top = top + 'px';
            containerStyle.bottom = '';
            containerStyle.left = left + 'px';
            containerStyle.maxHeight = maxHeight + 'px';
        }
        // the calc method must be called twice, otherwise the calculation may be wrong on resize event (chrome browser)
        calc();
        calc();
        if (settings.customize && inputRect) {
            settings.customize(input, inputRect, container, maxHeight);
        }
    }
    /**
     * Redraw the autocomplete div element with suggestions
     */
    function update() {
        container.textContent = '';
        input.setAttribute('aria-activedescendant', '');
        // function for rendering autocomplete suggestions
        var render = function (item, _, __) {
            var itemElement = doc.createElement('div');
            itemElement.textContent = item.label || '';
            return itemElement;
        };
        if (settings.render) {
            render = settings.render;
        }
        // function to render autocomplete groups
        var renderGroup = function (groupName, _) {
            var groupDiv = doc.createElement('div');
            groupDiv.textContent = groupName;
            return groupDiv;
        };
        if (settings.renderGroup) {
            renderGroup = settings.renderGroup;
        }
        var fragment = doc.createDocumentFragment();
        var prevGroup = uid();
        items.forEach(function (item, index) {
            if (item.group && item.group !== prevGroup) {
                prevGroup = item.group;
                var groupDiv = renderGroup(item.group, inputValue);
                if (groupDiv) {
                    groupDiv.className += ' group';
                    fragment.appendChild(groupDiv);
                }
            }
            var div = render(item, inputValue, index);
            if (div) {
                div.id = container.id + "_" + index;
                div.setAttribute('role', 'option');
                div.addEventListener('click', function (ev) {
                    suppressAutocomplete = true;
                    try {
                        settings.onSelect(item, input);
                    }
                    finally {
                        suppressAutocomplete = false;
                    }
                    clear();
                    ev.preventDefault();
                    ev.stopPropagation();
                });
                if (item === selected) {
                    div.className += ' selected';
                    div.setAttribute('aria-selected', 'true');
                    input.setAttribute('aria-activedescendant', div.id);
                }
                fragment.appendChild(div);
            }
        });
        container.appendChild(fragment);
        if (items.length < 1) {
            if (settings.emptyMsg) {
                var empty = doc.createElement('div');
                empty.id = container.id + "_" + uid();
                empty.className = 'empty';
                empty.textContent = settings.emptyMsg;
                container.appendChild(empty);
                input.setAttribute('aria-activedescendant', empty.id);
            }
            else {
                clear();
                return;
            }
        }
        attach();
        updatePosition();
        updateScroll();
    }
    function updateIfDisplayed() {
        if (containerDisplayed()) {
            update();
        }
    }
    function resizeEventHandler() {
        updateIfDisplayed();
    }
    function scrollEventHandler(e) {
        if (e.target !== container) {
            updateIfDisplayed();
        }
        else {
            e.preventDefault();
        }
    }
    function inputEventHandler() {
        if (!suppressAutocomplete) {
            fetch(0 /* Keyboard */);
        }
    }
    /**
     * Automatically move scroll bar if selected item is not visible
     */
    function updateScroll() {
        var elements = container.getElementsByClassName('selected');
        if (elements.length > 0) {
            var element = elements[0];
            // make group visible
            var previous = element.previousElementSibling;
            if (previous && previous.className.indexOf('group') !== -1 && !previous.previousElementSibling) {
                element = previous;
            }
            if (element.offsetTop < container.scrollTop) {
                container.scrollTop = element.offsetTop;
            }
            else {
                var selectBottom = element.offsetTop + element.offsetHeight;
                var containerBottom = container.scrollTop + container.offsetHeight;
                if (selectBottom > containerBottom) {
                    container.scrollTop += selectBottom - containerBottom;
                }
            }
        }
    }
    function selectPreviousSuggestion() {
        var index = items.indexOf(selected);
        selected = index === -1
            ? undefined
            : items[(index + items.length - 1) % items.length];
        updateSelectedSuggestion(index);
    }
    function selectNextSuggestion() {
        var index = items.indexOf(selected);
        selected = items.length < 1
            ? undefined
            : index === -1
                ? items[0]
                : items[(index + 1) % items.length];
        updateSelectedSuggestion(index);
    }
    function updateSelectedSuggestion(index) {
        if (items.length > 0) {
            unselectSuggestion(index);
            selectSuggestion(items.indexOf(selected));
            updateScroll();
        }
    }
    function selectSuggestion(index) {
        var element = doc.getElementById(container.id + "_" + index);
        if (element) {
            element.classList.add('selected');
            element.setAttribute('aria-selected', 'true');
            input.setAttribute('aria-activedescendant', element.id);
        }
    }
    function unselectSuggestion(index) {
        var element = doc.getElementById(container.id + "_" + index);
        if (element) {
            element.classList.remove('selected');
            element.removeAttribute('aria-selected');
            input.removeAttribute('aria-activedescendant');
        }
    }
    function handleArrowAndEscapeKeys(ev, key) {
        var containerIsDisplayed = containerDisplayed();
        if (key === 'Escape') {
            clear();
        }
        else {
            if (!containerIsDisplayed || items.length < 1) {
                return;
            }
            key === 'ArrowUp'
                ? selectPreviousSuggestion()
                : selectNextSuggestion();
        }
        ev.preventDefault();
        if (containerIsDisplayed) {
            ev.stopPropagation();
        }
    }
    function handleEnterKey(ev) {
        if (selected) {
            if (preventSubmit === 2 /* OnSelect */) {
                ev.preventDefault();
            }
            suppressAutocomplete = true;
            try {
                settings.onSelect(selected, input);
            }
            finally {
                suppressAutocomplete = false;
            }
            clear();
        }
        if (preventSubmit === 1 /* Always */) {
            ev.preventDefault();
        }
    }
    function keydownEventHandler(ev) {
        var key = ev.key;
        switch (key) {
            case 'ArrowUp':
            case 'ArrowDown':
            case 'Escape':
                handleArrowAndEscapeKeys(ev, key);
                break;
            case 'Enter':
                handleEnterKey(ev);
                break;
        }
    }
    function focusEventHandler() {
        if (showOnFocus) {
            fetch(1 /* Focus */);
        }
    }
    function fetch(trigger) {
        if (input.value.length >= minLen || trigger === 1 /* Focus */) {
            clearDebounceTimer();
            debounceTimer = window.setTimeout(function () { return startFetch(input.value, trigger, input.selectionStart || 0); }, trigger === 0 /* Keyboard */ || trigger === 2 /* Mouse */ ? debounceWaitMs : 0);
        }
        else {
            clear();
        }
    }
    function startFetch(inputText, trigger, cursorPos) {
        if (destroyed)
            return;
        var savedFetchCounter = ++fetchCounter;
        settings.fetch(inputText, function (elements) {
            if (fetchCounter === savedFetchCounter && elements) {
                items = elements;
                inputValue = inputText;
                selected = (items.length < 1 || disableAutoSelect) ? undefined : items[0];
                update();
            }
        }, trigger, cursorPos);
    }
    function keyupEventHandler(e) {
        if (settings.keyup) {
            settings.keyup({
                event: e,
                fetch: function () { return fetch(0 /* Keyboard */); }
            });
            return;
        }
        if (!containerDisplayed() && e.key === 'ArrowDown') {
            fetch(0 /* Keyboard */);
        }
    }
    function clickEventHandler(e) {
        settings.click && settings.click({
            event: e,
            fetch: function () { return fetch(2 /* Mouse */); }
        });
    }
    function blurEventHandler() {
        // when an item is selected by mouse click, the blur event will be initiated before the click event and remove DOM elements,
        // so that the click event will never be triggered. In order to avoid this issue, DOM removal should be delayed.
        setTimeout(function () {
            if (doc.activeElement !== input) {
                clear();
            }
        }, 200);
    }
    function manualFetch() {
        startFetch(input.value, 3 /* Manual */, input.selectionStart || 0);
    }
    /**
     * Fixes #26: on long clicks focus will be lost and onSelect method will not be called
     */
    container.addEventListener('mousedown', function (evt) {
        evt.stopPropagation();
        evt.preventDefault();
    });
    /**
     * Fixes #30: autocomplete closes when scrollbar is clicked in IE
     * See: https://stackoverflow.com/a/9210267/13172349
     */
    container.addEventListener('focus', function () { return input.focus(); });
    // If the custom autocomplete container is already appended to the DOM during widget initialization, detach it.
    detach();
    /**
     * This function will remove DOM elements and clear event handlers
     */
    function destroy() {
        input.removeEventListener('focus', focusEventHandler);
        input.removeEventListener('keyup', keyupEventHandler);
        input.removeEventListener('click', clickEventHandler);
        input.removeEventListener('keydown', keydownEventHandler);
        input.removeEventListener('input', inputEventHandler);
        input.removeEventListener('blur', blurEventHandler);
        window.removeEventListener('resize', resizeEventHandler);
        doc.removeEventListener('scroll', scrollEventHandler, true);
        input.removeAttribute('role');
        input.removeAttribute('aria-expanded');
        input.removeAttribute('aria-autocomplete');
        input.removeAttribute('aria-controls');
        input.removeAttribute('aria-activedescendant');
        input.removeAttribute('aria-owns');
        input.removeAttribute('aria-haspopup');
        clearDebounceTimer();
        clear();
        destroyed = true;
    }
    // setup event handlers
    input.addEventListener('keyup', keyupEventHandler);
    input.addEventListener('click', clickEventHandler);
    input.addEventListener('keydown', keydownEventHandler);
    input.addEventListener('input', inputEventHandler);
    input.addEventListener('blur', blurEventHandler);
    input.addEventListener('focus', focusEventHandler);
    window.addEventListener('resize', resizeEventHandler);
    doc.addEventListener('scroll', scrollEventHandler, true);
    return {
        destroy: destroy,
        fetch: manualFetch
    };
}

class TagOption extends HTMLElement {
  constructor() {
    super();
    this._shadowRoot = this.attachShadow({ mode: "open" });
  }

  connectedCallback() {
    this._shadowRoot.innerHTML = `
      <style>
        :host {
          background: #588a00;
          padding: 3px 10px 3px 10px !important;
          margin-right: 4px !important;
          margin-bottom: 2px !important;
          display: inline-flex;
          align-items: center;
          float: none;
          font-size: 14px;
          line-height: 1;
          min-height: 32px;
          color: #fff;
          text-transform: none;
          border-radius: 3px;
          position: relative;
          cursor: pointer;
        }
        button {
          z-index: 1;
          border: none;
          background: none;
          font-size: 20px;
          display: inline-block;
          color: rgba(255, 255, 255, 0.6);
          right: 10px;
          height: 100%;
          cursor: pointer;
        }
      </style>
      <slot></slot>
      <button type="button">×</button>
    `;

    this.buttonTarget = this._shadowRoot.querySelector("button");
    this.buttonTarget.onclick = event => {
      this.parentNode._taggle._remove(this, event);
    };
  }

  get value() {
    return this.getAttribute("value") || this.innerText
  }

  get label() {
    return this.innerText
  }
}
customElements.define("tag-option", TagOption);


class InputTag extends HTMLElement {
  static get formAssociated() {
    return true;
  }

  static get observedAttributes() {
    return ['name', 'multiple', 'required', 'list'];
  }

  constructor() {
    super();
    this._internals = this.attachInternals();
    this._shadowRoot = this.attachShadow({ mode: "open" });

    this.observer = new MutationObserver(mutations => {
      let needsTagOptionsUpdate = false;
      let needsAutocompleteUpdate = false;

      for (const mutation of mutations) {
        if (mutation.type === 'childList') {
          const addedRemovedNodes = [...mutation.addedNodes, ...mutation.removedNodes];
          if (addedRemovedNodes.some(node => node.tagName === 'TAG-OPTION')) {
            needsTagOptionsUpdate = true;
          }
          if (addedRemovedNodes.some(node => node.tagName === 'DATALIST')) {
            needsAutocompleteUpdate = true;
          }
        } else if (mutation.type === 'attributes') {
          // Handle attribute changes on tag-option elements
          if (mutation.target !== this && mutation.target.tagName === 'TAG-OPTION') {
            needsTagOptionsUpdate = true;
          }
        }
      }

      if (needsTagOptionsUpdate || needsAutocompleteUpdate) {
        this.unobserve();
        if (needsTagOptionsUpdate) {
          this.processTagOptions();
        }
        if (needsAutocompleteUpdate && this.initialized) {
          this.setupAutocomplete();
        }
        this.observe();
      }
    });
  }

  unobserve() {
    this.observer.disconnect();
  }

  observe() {
    this.observer.observe(this, {
      childList: true,
      attributes: true,
      subtree: true,
      attributeFilter: ["value"],
    });
  }

  processTagOptions() {
    if(!this._taggle || !this._taggle.tag) return
    let tagOptions = Array.from(this.children).filter(e => e.tagName === 'TAG-OPTION');
    let values = tagOptions.map(e => e.value).filter(value => value !== null && value !== undefined);

    // Enforce maxTags constraint for single mode
    if (!this.multiple && values.length > 1) {
      // Remove excess tag-options from DOM (keep only the first one)
      tagOptions.slice(1).forEach(el => el.remove());
      tagOptions = tagOptions.slice(0, 1);
      values = values.slice(0, 1);
    }

    this._taggle.tag.elements = tagOptions;
    this._taggle.tag.values = values;
    this._inputPosition = this._taggle.tag.values.length;

    // Update the taggle display elements to match the current values
    const taggleElements = this._taggle.tag.elements;
    taggleElements.forEach((element, index) => {
      if (element && element.setAttribute) {
        element.setAttribute('data-value', values[index]);
      }
    });

    // Update internal value to match
    this.updateValue();

    // Ensure input visibility is updated when tags change via DOM
    this.updateInputVisibility();
  }

  get form() {
    return this._internals.form;
  }

  _setFormValue(values) {
    this._internals.value = values;

    const formData = new FormData();
    values.forEach(value => formData.append(this.name, value));
    // Always append empty string when no values so server knows to clear the field
    // (like Rails multiple checkboxes which prepend an empty hidden field)
    if (values.length === 0) {
      formData.append(this.name, "");
    }
    this._internals.setFormValue(formData);
  }

  get name() {
    return this.getAttribute("name");
  }

  get multiple() {
    return this.hasAttribute('multiple');
  }

  get value() {
    const internalValue = this._internals.value;
    if (this.multiple) {
      return internalValue; // Return array for multiple mode
    } else {
      return internalValue.length > 0 ? internalValue[0] : ''; // Return string for single mode
    }
  }

  set value(input) {
    // Convert input to array format for internal storage
    let values;
    if (Array.isArray(input)) {
      values = input;
    } else if (typeof input === 'string') {
      values = input === '' ? [] : [input];
    } else {
      values = [];
    }

    const oldValues = this._internals.value;
    this._setFormValue(values);

    // Update taggle to match the new values
    if (this._taggle && this.initialized) {
      this.suppressEvents = true; // Prevent infinite loops
      this._taggle.removeAll();
      if (values.length > 0) {
        this._taggle.add(values);
      }
      this.suppressEvents = false;
    }

    if(this.initialized && !this.suppressEvents && JSON.stringify(oldValues) !== JSON.stringify(values)) {
      this.dispatchEvent(new CustomEvent("change", {
        bubbles: true,
        composed: true,
      }));
    }
  }

  reset() {
    this._taggle.removeAll();
    this._taggleInputTarget.value = '';
  }

  get options() {
    const datalistId = this.getAttribute("list");
    if(datalistId) {
      const datalist = document.getElementById(datalistId);
      if(datalist) {
        return [...datalist.options].map(option => option.value).filter(value => value !== null && value !== undefined)
      }
    }

    // Fall back to nested datalist
    const nestedDatalist = this.querySelector('datalist');
    if(nestedDatalist) {
      return [...nestedDatalist.options].map(option => option.hasAttribute('value') ? option.value : option.textContent).filter(value => value !== null && value !== undefined)
    }

    return []
  }

  _getOptionsWithLabels() {
    const datalistId = this.getAttribute("list");
    if(datalistId) {
      const datalist = document.getElementById(datalistId);
      if(datalist) {
        return [...datalist.options].map(option => ({
          value: option.value,
          label: option.textContent || option.value
        })).filter(item => item.value !== null && item.value !== undefined)
      }
    }

    // Fall back to nested datalist
    const nestedDatalist = this.querySelector('datalist');
    if(nestedDatalist) {
      return [...nestedDatalist.options].map(option => ({
        value: option.hasAttribute('value') ? option.value : option.textContent,
        label: option.textContent || option.value
      })).filter(item => item.value !== null && item.value !== undefined)
    }

    return []
  }

  async connectedCallback() {
    this.setAttribute('tabindex', '0');
    this.addEventListener("focus", e => this.focus(e));

    // Wait for child tag-option elements to be fully connected
    await new Promise(resolve => setTimeout(resolve, 0));

    this._shadowRoot.innerHTML = `
      <style>
        :host { display: block; }
        :host *{
          position: relative;
          box-sizing: border-box;
          margin: 0;
          padding: 0;
        }
        #container {
          background: rgba(255, 255, 255, 0.8);
          padding: 6px 6px 3px;
          max-height: none;
          display: flex;
          margin: 0;
          flex-wrap: wrap;
          align-items: flex-start;
          min-height: 48px;
          line-height: 48px;
          width: 100%;
          border: 1px solid #d0d0d0;
          outline: 1px solid transparent;
          box-shadow: #ccc 0 1px 4px 0 inset;
          border-radius: 2px;
          cursor: text;
          color: #333;
          list-style: none;
          padding-right: 32px;
        }
        input {
          display: block;
          height: 38px;
          float: none;
          margin: 0;
          padding-left: 10px !important;
          padding-right: 30px !important;
          width: auto !important;
          min-width: 70px;
          font-size: 14px;
          width: 100%;
          line-height: 2;
          padding: 0 0 0 10px;
          border: 1px dashed #d0d0d0;
          outline: 1px solid transparent;
          background: #fff;
          box-shadow: none;
          border-radius: 2px;
          cursor: text;
          color: #333;
        }
        button {
          width: 38px;
          text-align: center;
          line-height: 36px;
          border: 1px solid #e0e0e0;
          font-size: 20px;
          color: #666;
          position: absolute !important;
          z-index: 10;
          right: 0px;
          top: 0;
          font-weight: 400;
          cursor: pointer;
          background: none;
        }
        .taggle_sizer{
          padding: 0;
          margin: 0;
          position: absolute;
          top: -500px;
          z-index: -1;
          visibility: hidden;
        }
        .ui-autocomplete{
          position: static !important;
          width: 100% !important;
          margin-top: 2px;
        }
        .ui-menu{
          margin: 0;
          padding: 6px;
          box-shadow: #ccc 0 1px 6px;
          z-index: 2;
          display: flex;
          flex-wrap: wrap;
          background: #fff;
          list-style: none;
          font-size: 14px;
          min-width: 200px;
        }
        .ui-menu .ui-menu-item{
          display: inline-block;
          margin: 0 0 2px;
          line-height: 30px;
          border: none;
          padding: 0 10px;
          text-indent: 0;
          border-radius: 2px;
          width: auto;
          cursor: pointer;
          color: #555;
        }
        .ui-menu .ui-menu-item::before{ display: none; }
        .ui-menu .ui-menu-item:hover{ background: #e0e0e0; }
        .ui-state-active{
          padding: 0;
          border: none;
          background: none;
          color: inherit;
        }
      </style>
      <div style="position: relative;">
        <div id="container">
          <slot></slot>
        </div>
        <input
          id="inputTarget"
          type="hidden"
          name="${this.name}"
        />
      </div>
    `;

    this.form?.addEventListener("reset", this.reset.bind(this));

    this.containerTarget = this.shadowRoot.querySelector("#container");
    this.inputTarget = this.shadowRoot.querySelector("#inputTarget");

    this.required = this.hasAttribute("required");

    const maxTags = this.multiple ? undefined : 1;
    const placeholder = this.inputTarget.getAttribute("placeholder");

    this.inputTarget.value = "";
    this.inputTarget.id = "";

    this._taggle = new Taggle(this, {
      inputContainer: this.containerTarget,
      preserveCase: true,
      hiddenInputName: this.name,
      maxTags: maxTags,
      placeholder: placeholder,
      onTagAdd: (event, tag) => this.onTagAdd(event, tag),
      onTagRemove: (event, tag) => this.onTagRemove(event, tag),
    });
    this._taggleInputTarget = this._taggle.getInput();
    this._taggleInputTarget.id = this.id;
    this._taggleInputTarget.autocomplete = "off";
    this._taggleInputTarget.setAttribute("data-turbo-permanent", true);
    this._taggleInputTarget.addEventListener("keyup", e => this.keyup(e));

    // Set initial value after taggle is initialized
    this.value = this._taggle.getTagValues();

    this.checkRequired();

    this.buttonTarget = h(`<button class="add">+</button>`);
    this.buttonTarget.addEventListener("click", e => this._add(e));
    this._taggleInputTarget.insertAdjacentElement("afterend", this.buttonTarget);

    this.autocompleteContainerTarget = h(`<ul>`);
    // Insert autocomplete container into the positioned wrapper div
    const wrapperDiv = this.shadowRoot.querySelector('div[style*="position: relative"]');
    wrapperDiv.appendChild(this.autocompleteContainerTarget);

    this.setupAutocomplete();

    this.observe(); // Start observing after taggle is set up
    this.initialized = true;

    // Update visibility based on current state
    this.updateInputVisibility();
  }

  setupAutocomplete() {
    const optionsWithLabels = this._getOptionsWithLabels();

    autocomplete({
      input: this._taggleInputTarget,
      container: this.autocompleteContainerTarget,
      className: "ui-menu ui-autocomplete",
      fetch: (text, update) => {
        const currentTags = this._taggle.getTagValues();
        const suggestions = optionsWithLabels.filter(option =>
          option.label.toLowerCase().includes(text.toLowerCase()) &&
          !currentTags.includes(option.value)
        );
        // Store the suggestions for testing (can't assign to getter, tests read from DOM)
        update(suggestions);
      },
      render: item => h(`<li class="ui-menu-item" data-value="${item.value}">${item.label}</li>`),
      onSelect: item => {
        // Prevent adding multiple tags in single mode
        if (!this.multiple && this._taggle.getTagValues().length > 0) {
          this._taggleInputTarget.value = '';
          return
        }

        // Create a tag-option element with proper value/label separation
        const tagOption = document.createElement('tag-option');
        tagOption.setAttribute('value', item.value);
        tagOption.textContent = item.label;
        this.appendChild(tagOption);

        // Clear input
        this._taggleInputTarget.value = '';
      },
      minLength: 1,
      customize: (input, inputRect, container, maxHeight) => {
        // Position autocomplete below the input-tag container, accounting for dynamic height
        this._updateAutocompletePosition(container);

        // Store reference to update positioning when container height changes
        this._autocompleteContainer = container;
      }
    });
  }

  disconnectedCallback() {
    this.form?.removeEventListener("reset", this.reset.bind(this));
    this.unobserve();
  }

  attributeChangedCallback(name, oldValue, newValue) {
    if (oldValue === newValue) return;

    // Only handle changes after the component is connected and initialized
    if (!this._taggle) return;

    switch (name) {
      case 'name':
        this.handleNameChange(newValue);
        break;
      case 'multiple':
        this.handleMultipleChange(newValue !== null);
        break;
      case 'required':
        this.handleRequiredChange(newValue !== null);
        break;
      case 'list':
        this.handleListChange(newValue);
        break;
    }
  }

  checkRequired() {
    const flag = this.required && this._taggle.getTagValues().length == 0;
    this._taggleInputTarget.required = flag;

    // Update ElementInternals validity to match internal input
    if (flag) {
      this._internals.setValidity({ valueMissing: true }, 'Please fill out this field.', this._taggleInputTarget);
    } else {
      this._internals.setValidity({});
    }
  }

  // monkeypatch support for android comma
  keyup(event) {
    const key = event.which || event.keyCode;
    const normalKeyboard = key != 229;
    if(normalKeyboard) return
    const value = this._taggleInputTarget.value;

    // backspace
    if(value.length == 0) {
      const values = this._taggle.tag.values;
      this._taggle.remove(values[values.length - 1]);
      return
    }

    // comma
    if(/,$/.test(value)) {
      const tag = value.replace(',', '');
      this._taggle.add(tag);
      this._taggleInputTarget.value = '';
      return
    }
  }

  _add(event) {
    event.preventDefault();
    this._taggle.add(this._taggleInputTarget.value);
    this._taggleInputTarget.value = '';
  }

  onTagAdd(event, tag) {
    if (!this.suppressEvents) {
      const isNew = !this.options.includes(tag);
      this.dispatchEvent(new CustomEvent("update", {
        detail: { tag, isNew },
        bubbles: true,
        composed: true,
      }));
    }
    this.syncValue();
    this.checkRequired();
    this.updateInputVisibility();

    // Update autocomplete position if it's currently open
    if (this._autocompleteContainer) {
      // Use setTimeout to allow DOM to update first
      setTimeout(() => this._updateAutocompletePosition(this._autocompleteContainer), 0);
    }
  }

  onTagRemove(event, tag) {
    if (!this.suppressEvents) {
      this.dispatchEvent(new CustomEvent("update", {
        detail: { tag },
        bubbles: true,
        composed: true,
      }));
    }
    this.syncValue();
    this.checkRequired();
    this.updateInputVisibility();

    // Update autocomplete position if it's currently open
    if (this._autocompleteContainer) {
      // Use setTimeout to allow DOM to update first
      setTimeout(() => this._updateAutocompletePosition(this._autocompleteContainer), 0);
    }
  }

  syncValue() {
    // Directly update internals without triggering the setter
    const values = this._taggle.getTagValues();
    const oldValues = this._internals.value;
    this._setFormValue(values);

    if(this.initialized && !this.suppressEvents && JSON.stringify(oldValues) !== JSON.stringify(values)) {
      this.dispatchEvent(new CustomEvent("change", {
        bubbles: true,
        composed: true,
      }));
    }
  }

  // Public API methods
  add(tags) {
    if (!this._taggle) return
    this._taggle.add(tags);
  }

  remove(tag) {
    if (!this._taggle) return
    this._taggle.remove(tag);
  }

  removeAll() {
    if (!this._taggle) return
    this._taggle.removeAll();
  }

  has(tag) {
    if (!this._taggle) return false
    return this._taggle.getTagValues().includes(tag)
  }

  get tags() {
    if (!this._taggle) return []
    return this._taggle.getTagValues()
  }

  // Private getter for testing autocomplete suggestions
  get _autocompleteSuggestions() {
    if (!this.autocompleteContainerTarget) return []
    const items = this.autocompleteContainerTarget.querySelectorAll('.ui-menu-item');
    return Array.from(items).map(item => item.textContent.trim())
  }

  // Update autocomplete position based on current container height
  _updateAutocompletePosition(container) {
    if (!container) return

    const inputTagRect = this.containerTarget.getBoundingClientRect();

    container.style.setProperty('position', 'absolute', 'important');
    container.style.setProperty('top', `${inputTagRect.height}px`, 'important');
    container.style.setProperty('left', '0', 'important');
    container.style.setProperty('right', '0', 'important');
    container.style.setProperty('width', '100%', 'important');
    container.style.setProperty('z-index', '1000', 'important');
  }

  updateInputVisibility() {
    if (!this._taggleInputTarget || !this.buttonTarget) return;

    const hasTags = this._taggle && this._taggle.getTagValues().length > 0;

    if (this.multiple) {
      // Multiple mode: always show input and button
      this._taggleInputTarget.style.display = '';
      this.buttonTarget.style.display = '';
    } else {
      // Single mode: hide input and button when tag exists
      if (hasTags) {
        this._taggleInputTarget.style.display = 'none';
        this.buttonTarget.style.display = 'none';
      } else {
        this._taggleInputTarget.style.display = '';
        this.buttonTarget.style.display = '';
      }
    }
  }

  addAt(tag, index) {
    if (!this._taggle) return
    this._taggle.add(tag, index);
  }

  disable() {
    if (this._taggle) {
      this._taggle.disable();
    }
  }

  enable() {
    if (this._taggle) {
      this._taggle.enable();
    }
  }

  focus() {
    if (this._taggleInputTarget) {
      this._taggleInputTarget.focus();
    }
  }

  checkValidity() {
    if (this._taggle) {
      this.checkRequired();
    }
    return this._internals.checkValidity()
  }

  reportValidity() {
    if (this._taggle) {
      this.checkRequired();
    }
    return this._internals.reportValidity()
  }

  handleNameChange(newName) {
    // Update the hidden input name to match
    const hiddenInput = this._shadowRoot.querySelector('input[type="hidden"]');
    if (hiddenInput) {
      hiddenInput.name = newName || '';
    }

    // Update the form value with the new name
    if (this._internals.value) {
      this.value = this._internals.value; // This will recreate FormData with new name
    }
  }

  handleMultipleChange(isMultiple) {
    if (!this._taggle) return;

    // Get current tags
    const currentTags = this._taggle.getTagValues();

    if (!isMultiple && currentTags.length > 1) {
      // Single mode: remove excess tag-option elements from DOM
      const tagOptions = Array.from(this.children);
      // Keep only the first tag-option element, remove the rest
      tagOptions.forEach((tagOption, i) => {
        if (i > 0 && tagOption) {
          this.removeChild(tagOption);
        }
      });
    }

    // Reinitialize taggle with new multiple setting
    this.reinitializeTaggle();

    // Restore tags, respecting the new multiple constraint
    if (isMultiple) {
      // Multiple mode: restore all remaining tags
      if (currentTags.length > 0) {
        this._taggle.add(currentTags);
      }
    } else {
      // Single mode: keep only the first tag
      if (currentTags.length > 0) {
        this._taggle.add(currentTags[0]);
      }
    }

    this.updateValue();
    this.updateInputVisibility();
  }

  handleRequiredChange(isRequired) {
    if (!this._taggle) return;

    // Update the internal required state
    this.required = isRequired;

    // Update validation
    this.checkRequired();
  }

  handleListChange(newListId) {
    if (!this._taggle) return;

    // Re-setup autocomplete with new datalist
    this.setupAutocomplete();
  }

  reinitializeTaggle() {
    // Clean up existing taggle if it exists
    if (this._taggle && this._taggle.destroy) {
      this._taggle.destroy();
    }

    // Get current configuration
    const maxTags = this.hasAttribute("multiple") ? undefined : 1;
    const placeholder = this.getAttribute("placeholder") || "";

    // Create new taggle instance using original configuration pattern
    this._taggle = new Taggle(this, {
      inputContainer: this.containerTarget,
      preserveCase: true,
      hiddenInputName: this.name,
      maxTags: maxTags,
      placeholder: placeholder,
      onTagAdd: (event, tag) => this.onTagAdd(event, tag),
      onTagRemove: (event, tag) => this.onTagRemove(event, tag),
    });

    // Re-get references since taggle was recreated
    this._taggleInputTarget = this._taggle.getInput();
    this._taggleInputTarget.id = this.id || "";
    this._taggleInputTarget.autocomplete = "off";
    this._taggleInputTarget.setAttribute("data-turbo-permanent", true);
    this._taggleInputTarget.addEventListener("keyup", e => this.keyup(e));

    // Re-setup autocomplete
    this.setupAutocomplete();

    // Re-process existing tag options
    this.processTagOptions();
  }

  updateValue() {
    if (!this._taggle) return;

    // Update the internal value to match taggle state
    const values = this._taggle.getTagValues();
    const oldValues = this._internals.value;
    this._setFormValue(values);

    // Check validity after updating
    this.checkRequired();

    if(this.initialized && !this.suppressEvents && JSON.stringify(oldValues) !== JSON.stringify(values)) {
      this.dispatchEvent(new CustomEvent("change", {
        bubbles: true,
        composed: true,
      }));
    }
  }
}
customElements.define("input-tag", InputTag);


function h(html) {
  const container = document.createElement("div");
  container.innerHTML = html;
  return container.firstElementChild
}
