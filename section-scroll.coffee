disableScroll = (e) ->
  e.preventDefault()
  return false

snapSectionsProto =
  currentList: undefined
  currentItem: undefined
  currentPlaneId: undefined
  $planes: $('.js-snap-plane')
  $main: $('.js-main-wrap')
  $body: $('body')
  currentScroll: 0
  animating: false
  lastScroll: 0
  scrollBarrier: 40
  inSection: false
  entDetected: false
  scrollBuildup: 0
  animateBarrier: 400
  scrollRatio: 1
  dummies: undefined
  overshot: 0
  scrollDirr: false
  window: {}

SnapSections = Object.create snapSectionsProto
SnapSections.checkCurrPlane = ($plane, count = 0) ->
  _this = @
  sY = window.scrollY
  $sections = $plane.children()

  _this.currentPlaneId = count
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

SnapSections.calcScrDirr = () ->
  if @.currentItem.length > 0 && !@.animating && @.lastScroll - @.scrollBarrier > window.scrollY
    @.scrollDirr = 'up'
  else if @.currentItem.length > 0  && !@.animating && @.lastScroll + @.scrollBarrier < window.scrollY
    @.scrollDirr = 'down'
  else
    @.scrollDirr = false
  return

SnapSections.calcOvershot = () ->
  if @.scrollDirr == 'down'
    @.overshot = window.scrollY - @.$planes[@.currentPlaneId].orgnPosTop
  else if  @.scrollDirr == 'up'
    @.overshot = window.scrollY - (@.$planes[@.currentPlaneId].orgnPosTop + @.currentList.height())

SnapSections.windowScroll = (evt, cb) ->
  if !@.animating
    _this = @
    if typeof @.currentList == 'undefined'
      @.currentList = @.checkCurrPlane @.$planes.first()
    if typeof @.currentList != 'undefined' && !@.inSection
      @.inSection = true
      @.currentItem = @.determineSection @currentList.children()
      @.calcScrDirr.call _this
      @.calcOvershot.call _this
    else if @.inSection
      @.calcScrDirr.call _this
      cb.call _this
  else
    return false

SnapSections.enableScroll = (scroll) ->
  _this = @
  setTimeout(->
    _this.animating = false
  , 125)

SnapSections.entDetection = () ->
  if @.entDetected
    if @.scrollDirr == 'down'
      @.window.scroll = @.$planes[@.currentPlaneId].orgnPosTop
    else
      @.window.scroll = @.$planes[@.currentPlaneId].orgnPosTop + $(@.$planes[@.currentPlaneId]).height()

SnapSections.animateBody = (scroll) ->
  if @.scrollDirr == 'up'
    $('body').scrollTop(scroll + @.currentItem.height())
  else if @.scrollDirr == 'down'
    $('body').scrollTop(scroll - @.currentItem.height())
  $('body').animate {scrollTop: scroll}, {duration: 400}
  return

SnapSections.planeExit = () ->
  @.currentList.css {
    'top': @.$planes[@.currentPlaneId].orgnPosTop
    'position': 'absolute'
  }
  @.currentList = undefined
  @.currentItem = undefined
  @.inSection = false
  @.currentScroll = 0

SnapSections.handleScroll = () ->
  if @.scrollDirr == 'down'
    @.animating = true
    @.entDetection()
    currItemHeight = @.currentItem.height()
    scroll = currItemHeight + @.window.scroll
    contentScroll = currItemHeight + @.currentScroll
    @.window.scroll = scroll
    _this = @
    @.currentList.css
      'top': -@.currentScroll - @.overshot
      'position': 'fixed'
    @.animateBody scroll
    @.currentList.animate {top: -contentScroll}, { duration: 400, complete: () ->
      _this.overshot = 0
      _this.entDetected = false
      _this.lastScroll = scroll
      _this.currentScroll = contentScroll
      _this.currentItem = _this.currentItem.next().first()
      _this.enableScroll(scroll)
      if _this.currentItem.length == 0
        _this.planeExit.call _this
    }
  else if @.scrollDirr == 'up'
    @.animating = true
    @.entDetection()
    if @.entDetected
      scroll = @.currentScroll + @.currentList.height() - @.currentItem.height()
      bodyScroll = @.currentList.height() + @.$planes[@.currentPlaneId].orgnPosTop - @.currentItem.height()
      scrollFrom = -@.currentList.height()
    else
      scroll = @.currentScroll - @.currentItem.height()
      bodyScroll = @.lastScroll - @.currentItem.height()
      scrollFrom = -@.currentScroll

    @.currentList.css
      'top': scrollFrom + @.overshot
      'position': 'fixed'

    _this = @
    @.window.scroll = bodyScroll
    @.animateBody bodyScroll
    @.currentList.animate {top: -scroll}, { duration: 400, complete: () ->
      _this.lastScroll = bodyScroll
      _this.currentScroll = scroll

      if !_this.entDetected
        _this.currentItem = _this.currentItem.prev()
      _this.overshot = 0
      _this.entDetected = false
      _this.enableScroll(scroll)
      if _this.currentItem.length == 0
        _this.planeExit.call _this
    }

SnapSections.setupDummies = () ->
  _this = @
  _this.dummies = []

  @.$planes.each (i, elm) ->
    $elm = $(elm)
    $planeMimic = $(document.createElement('DIV')).addClass "js-snap-scrolling-#{i}"
    $planeMimic.height($elm.height() * _this.scrollRatio)
    _this.dummies.push $planeMimic
    $planeMimic.insertAfter($elm)
    $elm.css
      'width': '100%'
      'height': $elm.height()
      'position': 'absolute'
      'top': $elm.orgnPosTop
      'left': 0


SnapSections.init = () ->
  _this = @

  for i in [0...@.$planes.length] by 1
    @.$planes[i].orgnPosTop = $(@.$planes[i]).position().top

  @.setupDummies()
  $(window).scroll (evt) ->
    _this.windowScroll.call(_this, evt, _this.handleScroll)

snapSections = Object.create SnapSections

$(document).ready () ->
  snapSections.init()
