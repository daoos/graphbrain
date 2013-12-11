aiChatVisible = false

chatBuffer = []
chatBufferPos = 0
chatBufferSize = 100

initChatBuffer = () ->
  firstUse = false

  if localStorage.getItem('chatBufferPos') != null
    chatBufferPos = parseInt(localStorage.getItem('chatBufferPos'))
  else
    firstUse = true

  for pos in [0..chatBufferSize]
    chatBuffer.push(localStorage.getItem('chatBuffer' + pos))

  curPos = chatBufferPos
  while curPos < chatBufferSize
    line = chatBuffer[curPos]
    if line != null
      aiChatAddLineRaw(line)
    curPos += 1
  curPos = 0
  while curPos < chatBufferPos
    line = chatBuffer[curPos]
    if line != null
      aiChatAddLineRaw(line)
    curPos += 1

  if firstUse
    printHelp()

clearChatBuffer = () ->
  localStorage.removeItem('chatBufferPos')
  for pos in [0..chatBufferSize]
    localStorage.removeItem('chatBuffer' + pos)

aiChatGotoBottom = () ->
  height = $('#ai-chat')[0].scrollHeight
  $('#ai-chat').scrollTop(height)

showAiChat = () ->
  $('#ai-chat').css('display', 'block')
  aiChatVisible = true
  localStorage.setItem('aichat', 'true')
  aiChatGotoBottom()
  $('#ai-chat-input').focus()

hideAiChat = () ->
  $('#ai-chat').css('display', 'none')
  aiChatVisible = false
  localStorage.setItem('aichat', 'false')

initAiChat = () ->
  html = """
  <div id="ai-chat-log" />
  <form id="ai-chat-form">
  <input id="ai-chat-input" type="text" />
  </form>
  """
  $('#ai-chat').html(html)
  $('#ai-chat-form').submit(aiChatSubmit)

  initChatBuffer()

  if localStorage.getItem('aichat') == 'false'
    hideAiChat()
  else
    $("#ai-chat-button").button('toggle')
    showAiChat()

aiChatAddLineRaw = (line) ->
  $('#ai-chat-log').append(line)
  aiChatGotoBottom()

aiChatAddLine = (agent, line) ->
  html = ''
  if (agent == 'gb')
    html += '<div class="gb-line"><b>GraphBrain:</b> '
  else if (agent == 'user')
    html += '<div class="user-line"><b>You:</b> '
  html += line + '</div>'
  aiChatAddLineRaw(html)
  chatBuffer[chatBufferPos] = html
  localStorage.setItem('chatBuffer' + chatBufferPos, html)
  chatBufferPos += 1
  if chatBufferPos >= chatBufferSize
    chatBufferPos = 0
  localStorage.setItem('chatBufferPos', chatBufferPos)

printHelp = () ->
  helpMsg = """
GraphBrain allows you to record facts as relationships between entities (web resources, objects, concepts).<br />
To add a fact, simply type a sentence with a verb linking two entities (objects, concepts, websites), e.g.<br />

<b>GraphBrain likes people</b><br />
<b>GraphBrain lives at http://graphbrain.com</b><br />

In cases where there may be ambiguity, try to use quotation marks, e.g.<br />
<b>"Burn after reading" is a film</b> <br />
  """
  aiChatAddLine('gb', helpMsg)

aiChatSubmit = (msg) ->
  sentence = $('#ai-chat-input').val()
  aiChatAddLine('user', sentence)
  $('#ai-chat-input').val('')

  if sentence == '!clean'
    clearChatBuffer()
    location.href = location.href
    return false

  if sentence == 'help'
    printHelp()
    return false

  $.ajax({
    type: "POST",
    url: "/ai",
    data: "sentence=" + sentence + "&rootId=" + rootNodeId,
    dataType: "json",
    success: aiChatReply
  })
  false

aiChatReply = (msg) ->
  aiChatAddLine('gb', msg['sentence'])

  #console.log(msg['newedges'])
  state.setNewEdges(msg['newedges'])

  if msg['goto'] != ''
    window.location.href = '/node/' + msg['goto']

aiChatButtonPressed = (msg) ->
  if aiChatVisible
    hideAiChat()
  else
    showAiChat()

root = exports ? this
root.aiChatDisambiguate = (mode, text, rel, participantIds, pos) ->
  disambiguateQuery(mode, text, rel, participantIds, pos)