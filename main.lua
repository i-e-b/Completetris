-- vim:ts=2 sw=2
local deque = require "deque"

local screenWidth, screenHeight
local assets = {textfont, blockfont}

local bag = {} -- source of tiles
local currentTile = nil
local board = {grid, width=7, height=14} -- grid of blocks, with a width
local input = {up,down,left,right} -- arrow keys
local stepTime = 1.0 -- smaller = harder levels

function love.load()
  math.randomseed(os.time())
  love.window.fullscreen = (love.system.getOS() == "Android")
  screenWidth, screenHeight = love.graphics.getDimensions( )
  clearBoard()

  -- 36 high
  assets.textfont = love.graphics.newImageFont("assets/font.png", " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-.,?!")
  -- 32 high :: use an img font for a cheap sprite sheet. The letters are roughly how the shape looks
  assets.blockfont = love.graphics.newImageFont("assets/blockfont.png", " nu<>xXr7LJAUCD#")
end

-- Draw a frame
function love.draw()
  -- draw grid
  love.graphics.setFont(assets.blockfont)
  love.graphics.setColor(100, 240, 180, 255)
  local bx = (screenWidth - (board.width * 32)) / 2
  local by = (screenHeight - (board.height * 32)) / 2
  for i=0,board.height-1 do
    for j=0,board.width-1 do
      love.graphics.print(board.grid[(i*board.width) + j], bx + (j * 32), by + (i * 32))
    end
  end

  -- draw dropping tile
  if (currentTile) then
    love.graphics.setColor(255, 200, 20, 255)
    love.graphics.print(currentTile.tile, bx + (currentTile.x * 32), by + (currentTile.y * 32))
  end

  -- draw 'floor'
  love.graphics.setColor(40, 140, 80, 255)
  love.graphics.rectangle("fill", 0, by + (board.height * 32), screenWidth, 32)
  love.graphics.rectangle("fill", bx - 32, by, 32, screenHeight - (by*2) )
  love.graphics.rectangle("fill", bx + (board.width * 32), by, 32, screenHeight - (by*2) )

  -- draw the tile bag
  love.graphics.setColor(127, 100, 10, 255)
  for i, tile in ipairs(bag) do
    love.graphics.print(tile, (screenWidth/3)*2, by + (i * 40) - 32)
  end

  -- TODO: status
  love.graphics.setFont(assets.textfont)
  love.graphics.setColor(255, 200, 20, 255)
  love.graphics.print("COMPLETE-TRIS", 32, 32)
end

function love.keypressed(key)
  if key == 'escape' then love.event.quit() end
end

-- Update, with frame time in fractional seconds
local time = 0
function love.update(dt)
  if (dt < 0.4) then time = time + dt end -- prevent frame skips

  readInput()
  fillBag()
  checkTile()

  if (time > stepTime) then
    time = time - stepTime
    tryDropTile()
  end
end

function clearBoard()
  board.grid = {}
  for i=0,board.height-1 do
    for j=0,board.width-1 do
      board.grid[(i*board.width) + j] = ' ' -- chars for graphics, to match the block font
    end
  end
end

function rotateCW(src)
  --" nu<>xXr7LJAUCD#"
  if (src == ' ') then return ' '
  elseif (src == 'n') then return '>'
  elseif (src == '>') then return 'u'
  elseif (src == 'u') then return '<'
  elseif (src == '<') then return 'n'
  elseif (src == 'x') then return 'X'
  elseif (src == 'X') then return 'x'
  elseif (src == 'r') then return '7'
  elseif (src == '7') then return 'J'
  elseif (src == 'J') then return 'L'
  elseif (src == 'L') then return 'r'
  elseif (src == 'A') then return 'D'
  elseif (src == 'D') then return 'U'
  elseif (src == 'U') then return 'C'
  elseif (src == 'C') then return 'A'
  elseif (src == '#') then return '#' end
end

function scoreBoard()

  local groupNumber = 0
  local groups = {}
  local pairList = deque.new()
  local failedGroups = {}
  local trace = ""

  for y=0,board.height-1 do
    for x=0,board.width-1 do
      while (not pairList:is_empty()) do
        local pair = pairList:pop_right()
        local targetGroup = Get(groups, pair.dstX, pair.dstY)
        if compatibleGroup(pair.group, targetGroup) and areJoined(pair) then
          Set(groups, pair.dstX, pair.dstY, pair.group)
          addEdges(x,y, pair.group, pairList, groups)
        else
          trace = trace .. " x" .. pair.group
          failedGroups[pair.group] = true
        end
      end

      -- add untouched, non empty tiles to the search
      if (not Get(groups, x, y)) and (Get(board.grid, x, y) ~= ' ') then
        groupNumber = groupNumber + 1
        local added = addEdges(x,y, groupNumber, pairList, groups)
        if (added < 1) then error('bad edges for '..x..','..y..' : '..Get(board.grid, x, y)) end
      end
    end
  end
  -- all groups not in failed groups get scored
  -- we count them all together... if you get two small
  -- groups to score at once, that's the same as an equal sized
  -- single group
  local OK = false
  for check=1,groupNumber do
    if not (failedGroups[check]) then
      OK = true
      trace = trace .. " Y" .. check
    end
  end

  if OK then error(trace) end
end

function addEdges(x,y, groupNumber, pairList, groups)
  local newEdges = edgesOf(x, y)
  for i,newEdge in ipairs(newEdges) do
    -- if it's not got *our* group, add it.
    if (Get(groups, newEdge.x, newEdge.y) ~= groupNumber)  then
      pairList:push_right({
        srcX=x, srcY=y,
        dstX=newEdge.x, dstY=newEdge.y, group=groupNumber})
    end
  end
  return #newEdges
end

function edgesOf(sx, sy)
  local res = {}
  local tileType = Get(board.grid, sx, sy)

  if isEdgeAt(tileType, -1,  0) then table.insert(res, {x=sx - 1, y=sy}) end
  if isEdgeAt(tileType,  0, -1) then table.insert(res, {x=sx, y=sy - 1}) end
  if isEdgeAt(tileType,  1,  0) then table.insert(res, {x=sx + 1, y=sy}) end
  if isEdgeAt(tileType,  0,  1) then table.insert(res, {x=sx, y=sy + 1}) end

  return res
end

function Get(array, x,y)
  return array[(y*board.width) + x]
end
function Set(array, x,y, value)
  array[(y*board.width) + x] = value
end

function compatibleGroup(src, dst)
  return (dst == nil) or (src == dst)
  -- if dst has same group, or no group return true, else false
end

function areJoined(pair)
  -- pair.srcX, pair.srcY, pair.dstX, pair.dstY
  -- if the tiles share edges, return true. else false
  -- e.g. if a tile at 3,4 has a top edge and 3,5 has a bottom edge, this is true
  local sdx = pair.dstX - pair.srcX;
  local dsx = pair.srcX - pair.dstX;
  local sdy = pair.dstY - pair.srcY;
  local dsy = pair.srcY - pair.dstY;

  local src = Get(board.grid, pair.srcX, pair.srcY)
  local dst = Get(board.grid, pair.dstX, pair.dstY)

  return (isEdgeAt(src, sdx, dsy)) and (isEdgeAt(dst, dsx, sdy))
end

function isEdgeAt(tileType, dx, dy)
  --" nu<>xXr7LJAUCD#"
  if tileType == ' ' then
    return false
  elseif tileType == '#' then
    return true
  elseif tileType == 'n' then
    return dx == 0 and dy < 0 -- TODO: double check the direction...
  elseif tileType == 'u' then
    return dx == 0 and dy > 0
  elseif tileType == '<' then
    return dx > 0 and dy == 0
  elseif tileType == '>' then
    return dx < 0 and dy == 0
  elseif tileType == 'x' then
    return dy == 0
  elseif tileType == 'X' then
    return dx == 0
  elseif tileType == 'r' then
    return (dx > 0 and dy == 0) or (dx == 0 and dy < 0)
  elseif tileType == '7' then
    return (dx < 0 and dy == 0) or (dx == 0 and dy < 0)
  elseif tileType == 'L' then
    return (dx > 0 and dy == 0) or (dx == 0 and dy > 0)
  elseif tileType == 'J' then
    return (dx < 0 and dy == 0) or (dx == 0 and dy > 0)
  elseif tileType == 'A' then
    return not (dx == 0 and dy < 0)
  elseif tileType == 'U' then
    return not (dx == 0 and dy > 0)
  elseif tileType == 'C' then
    return not (dx > 0 and dy == 0)
  elseif tileType == 'D' then
    return not (dx < 0 and dy == 0)
  end
  error('bad tile '..tileType)
end

function readInput()
  local newInput = {}
  newInput.up = love.keyboard.isDown("up")
  newInput.down = love.keyboard.isDown("down")
  newInput.left = love.keyboard.isDown("left")
  newInput.right = love.keyboard.isDown("right")

  if (newInput.left and not input.left) and (currentTile.x > 0) then
    trySlideTile(-1)
  end
  if (newInput.right and not input.right) and (currentTile.x < board.width - 1) then
    trySlideTile(1)
  end
  if (newInput.up and not input.up) then
    currentTile.tile = rotateCW(currentTile.tile)
  end
  if (newInput.down and not input.down) then
    tryDropTile()
  end

  input = newInput
end

function checkTile()
  if (currentTile ~= nil) then return end
  local next = table.remove(bag, 1)
  currentTile = {tile=next, x=3, y=0}
end

function tryDropTile()
  local ny = currentTile.y + 1;
  local bottom = ny >= board.height
  if (not bottom) and (board.grid[(ny*board.width) + currentTile.x] == ' ') then
    currentTile.y = ny
  else -- lock the tile
    board.grid[(currentTile.y*board.width) + currentTile.x] = currentTile.tile
    currentTile = nil
    scoreBoard()
  end
end

function trySlideTile(dx)
  local nx = currentTile.x + dx;
  if (board.grid[(currentTile.y*board.width) + nx] == ' ') then
    currentTile.x = nx
  end
end

function random(min, max)
  return min + math.floor(math.random() * (max - min + 1))
end

function shuffle(list)
  local shuffled = {}
  local len = 0

  for k, v in pairs(list) do
    j = random(0, len)

    if j == len then
      table.insert(shuffled, v)
    else
      table.insert(shuffled, shuffled[j + 1])
      shuffled[j + 1] = v
    end

    len = len + 1
  end

  return shuffled
end

-- The 'normal' way to do tetris generation: start with a 'bag' of tiles,
-- shuffle, and dish out. Refill bag when empty. This keeps the distribution
-- of tiles controllable (both good and bad!)
function fillBag()
  if #bag > 0 then return end

  -- add tiles to be served. TODO: different bags for different levels
  local src = {'n','u','<','>'}--,'x','X','r','7','L','J','A','U','C','D','#'}
  bag = shuffle(src)
end
