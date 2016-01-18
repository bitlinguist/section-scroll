disableScroll = (e) ->
  e.preventDefault()
  return false

snapSectionsProto =
  currentList: undefined
  currentItem: undefined
  $planes: $('.js-snap-plane')
  currentScroll: 0
  animating: false
  lastScroll: 0
  scrollBarrier: 10
  inSection: false
  entDetected: false

SnapSections = Object.create snapSectionsProto
SnapSections.checkCurrPlane = ($plane, count = 0) ->
  _this = @
  sY = window.scrollY
  $sections = $plane.children()
  @.currentScroll = sY
  count++

  if (sY >= $sections.first().offset().top && sY <= $sections.last().offset().top + $sections.last().height() - 1)
    return $plane
  else if (@.$planes.length > count)
    return @checkCurrPlane($(@.$planes[count]), count)
  else
    return undefined

SnapSections.determineSection = ($sections) ->
  sY = window.scrollY
  elm = undefined
  _this = @

  $sections.each (i, item) ->
    _elm = $(item)

    if (sY >= _elm.offset().top && sY <= _elm.offset().top + _elm.height())
      elm = _elm
      if i == 0 || i == $sections.length - 1
        _this.entDetected = true

  return elm

SnapSections.windowScroll = (cb) ->
  if !@.animating
    _this = @
    if typeof @.currentList == 'undefined'
      @.currentList = @.checkCurrPlane @.$planes.first()
    if typeof @.currentList != 'undefined' && !@.inSection
      @.inSection = true
      @.currentItem = @.determineSection @currentList.children()
    else if @.inSection
      cb.call _this
  else
    return false

SnapSections.disableScroll = () ->
  $('body').css('position', 'fixed')
  $('body').css('overflow-y', 'scroll')

SnapSections.enableScroll = (scroll) ->
  $('body').css('position', 'static')
  $('body').css('overflow-y', 'auto')
  window.scrollTo(0, scroll)

SnapSections.handleScroll = () ->
  if @.currentItem.length > 0  && !@.animating && @.lastScroll + @.scrollBarrier < window.scrollY
    _this = @
    @.animating = true
    scroll = @.currentItem.offset().top + @.currentItem.height()
    $('body').css('top', -@.currentItem.offset().top)
    @.disableScroll()
    $('body').animate {top: -scroll}, { duration: 400, complete: () ->
      _this.animating = false
      _this.entDetected = false
      _this.lastScroll = scroll
      _this.currentScroll = scroll
      _this.currentItem = _this.currentItem.next().first()
      _this.enableScroll(scroll)
      if _this.currentItem.length == 0
        _this.currentList = undefined
        _this.currentItem = undefined
        _this.inSection = false
    }
  else if @.currentItem.length > 0 && !@.animating && @.lastScroll - @.scrollBarrier > window.scrollY
    _this = @
    @.animating = true
    if @.entDetected
      scroll = @.currentItem.offset().top
      scrollFrom = @.currentItem.offset().top + @.currentItem.height()
    else
      scroll = @.currentItem.offset().top - @.currentItem.height()
      scrollFrom = @.currentItem.offset().top

    $('body').css('top', -scrollFrom)
    @.disableScroll()
    $('body').animate {top: -scroll}, { duration: 400, complete: () ->
      _this.animating = false
      _this.lastScroll = scroll
      _this.currentScroll = scroll

      if !_this.entDetected
        _this.currentItem = _this.currentItem.prev()

      _this.entDetected = false
      _this.enableScroll(scroll)
      if _this.currentItem.length == 0
        _this.currentList = undefined
        _this.currentItem = undefined
        _this.inSection = false
    }


SnapSections.init = () ->
  _this = @
  $(window).scroll @.windowScroll.bind(_this, @.handleScroll)

snapSections = Object.create SnapSections

$(document).ready () ->
  snapSections.init()
