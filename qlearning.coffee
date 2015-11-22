# Actions = ['left', 'up', 'right', 'down']
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





################# Q learning stuff ###################################################

buildGridworld = (x,y)->
  states = {}
  buildStateActions = (row, col, x, y)->
    actions = []
    if row - 1 >= 0
      actions.push "#{row-1}-#{col}" #left
    if row + 1 < x
      actions.push "#{row+1}-#{col}" #right
    if col - 1 >= 0
      actions.push "#{row}-#{col-1}" #up
    if col + 1 < y
      actions.push "#{row}-#{col+1}" #down
    return actions

  # build world
  for row in [0...x]
    for col in [0...y]
      state = {}
      state.id = "#{row}-#{col}"
      state.actions = buildStateActions(row, col, x, y)
      state.Q = (0 for _ in state.actions)
      state.reward = Math.floor(Math.random() * 50)
      if Math.random() <= 0.5 then state.reward = -(state.reward)
      states[state.id] = state
  return states

argmax = (arr)->
  bestInd = 0
  for _, i in arr
    if arr[i] > bestInd
      bestInd = i
  bestInds = []
  for val, i in arr
    if val == arr[bestInd]
      bestInds.push i
  return randChoice(bestInds)

randChoice = (arr)->
  return arr[Math.floor(Math.random() * arr.length)]

R = (state, action)->
  return states[state.actions[action]].reward

# Query state for Q val. state is a state obj, action is the index of the action
Q = (state, action)->
  return state.Q[action]

# Q+1 function. state is a state obj, action is the index of the action
updateQ = (state, sprime, action)->
  bestQ = -Infinity
  for _,a in sprime.actions
    _q = Q(sprime, a) - Q(state, action)
    if _q >= bestQ then bestQ = _q
  state.Q[action] += lrate*(R(state, action) + discount*(bestQ))

pickState = (state)->
  if Math.random() <= 0.95
    aB = argmax(state.Q)
    bestId = state.actions[aB]
    return [states[bestId], aB]
  else
    aR = Math.floor(Math.random() * state.actions.length)
    randId = state.actions[aR]
    return [states[randId], aR]

######################################################################################


window.runVisualization = ->
  e = 0
  t = 0
  lastStep = false
  prevState = states['0-0']
  step = ->
    if lastStep
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
  window.states = buildGridworld(5,5)
  window.lrate = 0.1
  window.discount = 0.5
  setupVisualizer()

init()

# runSimulation = ->
#   for e in [0..5]
#     t = 10
#     prevState = states[0]
#     for [0..t]
#       # console.log prevState.id
#       [s, a] = pickState(prevState)
#       updateQ(prevState, s, a)
#       prevState = s

# if prevState.id == 'end'
#   setTimeout ->
#     lightUpCurrState(prevState, states['0-0'])
#     prevState = states['0-0']
#     setTimeout step, 200
#     e++
#     console.log "epoch #{e}"
#   , 200
# else
#   setTimeout step, 200
