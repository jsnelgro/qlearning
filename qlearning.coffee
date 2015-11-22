# states = {
#   0: id: 'start', actions: [1,3], reward: 0,  Q: [0,0,0,0]
#   1: id: 1, actions: [0,2,4],   reward: -10, Q: [0,0,0,0]
#   2: id: 2, actions: [1,5],     reward: -10, Q: [0,0,0,0]
#   3: id: 3, actions: [0,4,6],   reward: 10,  Q: [0,0,0,0]
#   4: id: 4, actions: [1,3,5,7], reward: 10, Q: [0,0,0,0]
#   5: id: 5, actions: [2,4,8],   reward: -10, Q: [0,0,0,0]
#   6: id: 6, actions: [3,7],     reward: -10,  Q: [0,0,0,0]
#   7: id: 7, actions: [6,8,4],   reward: 20,  Q: [0,0,0,0]
#   8: id: 'end', actions: [7,5], reward: 9999, Q: [0,0,0,0]
# }

########################## visualizer code ############################

setColor = (el, reward)->
  if reward < 0
    el.style.backgroundColor = "hsl(0,100%,#{100-Math.min(-reward, 70)}%)"
  else
    el.style.backgroundColor = "hsl(100,100%,#{100-Math.min(reward, 70)}%)"

setupVisualizer = ->
  row = '0'
  trow = document.createElement('div')
  trow.classList.add 'trow'

  for k in Object.keys(states)
    s = states[k]
    d = document.createElement('div')
    d.id = String(s.id)
    d.classList.add 'cell'
    d.innerHTML = String("<div>#{Math.floor s.Q[argmax(s.Q)]}</div>")
    d.onclick = (e)->
      state = window.states[e.path[1].id]
      console.log state
      if e.shiftKey
        state.reward -= 10
      else
        state.reward += 10

      setColor(e.path[1], state.reward)
    setColor(d, s.reward)
    if s.id[0] == row
      trow.appendChild(d)
    else
      document.getElementById('content').appendChild(trow)
      row = s.id[0]
      trow = document.createElement('div')
      trow.classList.add 'trow'
      trow.appendChild(d)
  document.getElementById('content').appendChild(trow)

lightUpCurrState = (prev, state)->
  old = document.getElementById(prev.id)
  curr = document.getElementById(state.id)
  setColor(old, prev.reward)
  old.classList.remove('active')
  curr.classList.add('active')
  curr.innerHTML = String("<div>#{Math.floor state.Q[argmax(state.Q)]}</div>")


#########################################################################



################# Q learning code ###################################################

buildGridworld = (x,y)->
  states = {}
  buildStateActions = (row, col, x, y)->
    actions = {}
    Q = {}
    if row - 1 >= 0
      actions.up = "#{row-1}-#{col}"
      Q.up = 0
    if row + 1 < x
      actions.down = "#{row+1}-#{col}"
      Q.down = 0
    if col - 1 >= 0
      actions.left = "#{row}-#{col-1}"
      Q.left = 0
    if col + 1 < y
      actions.right = "#{row}-#{col+1}"
      Q.right = 0
    return [actions, Q]

  # build world
  for row in [0...x]
    for col in [0...y]
      state = {}
      state.id = "#{row}-#{col}"
      [state.actions, state.Q] = buildStateActions(row, col, x, y)
      state.reward = -10
      if Math.random() <= 0.25 then state.reward = -(state.reward)
      states[state.id] = state
  return states

argmax = (obj)->
  bestKey = Object.keys(obj)[0]
  for k, v of obj
    if v >= obj[bestKey]
      bestKey = k
  bestKeys = []
  for k, v of obj
    if v == obj[bestKey]
      bestKeys.push k
  return randChoice(bestKeys)

randChoice = (arr)->
  unless Array.isArray(arr)
    arr = Object.keys arr
  return arr[Math.floor(Math.random() * arr.length)]

R = (state, action)->
  return states[state.actions[action]].reward

# Query state for Q val. state is a state obj, action is the index of the action
Q = (state, action)->
  return state.Q[action]

# Q+1 function. state is a state obj, action is the index of the action
updateQ = (state, sprime, action)->
  bestQ = -Infinity
  for actprime of sprime.actions
    testq = Q(sprime, actprime) - Q(state, action)
    if testq >= bestQ then bestQ = testq
  state.Q[action] += lrate*(R(state, action) + discount*(bestQ))

pickState = (state)->
  # TODO: this rand choice needs to be based on Q values or on a decreasing learning rate
  if Math.random() <= 0.95
    aB = argmax(state.Q)
    bestId = state.actions[aB]
    return [states[bestId], aB]
  else
    aR = randChoice(state.actions)
    randId = state.actions[aR]
    return [states[randId], aR]

######################################################################################


window.runVisualization = ->
  e = 0
  t = 0
  lastStep = false
  prevState = states['0-0']
  step = ->
    if lastStep or prevState.reward >= 70
      lastStep = false
      tempS = prevState
      prevState = states['0-0']
      lightUpCurrState(tempS, prevState)
    [s, a] = pickState(prevState)
    updateQ(prevState, s, a)
    lightUpCurrState(prevState, s)
    prevState = s
    setTimeout step, 200

  window.advanceEpoch = ->
    e++
    lastStep = true
  step()


init = ->
  window.states = buildGridworld(6,6)
  window.lrate = 0.1
  window.discount = 0.5
  setupVisualizer()

init()
