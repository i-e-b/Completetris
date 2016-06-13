local screenWidth, screenHeight
local assets = {textfont, blockfont}

local bag = {} -- source of tiles
local currentTile = {tile="X", x=3, y=0}
local board = {grid, width=7, height=14} -- grid of blocks, with a width
local input = {up,down,lefet,right} -- arrow keys
local stepTime = 1.0 -- smaller = harder levels


function love.load()
  love.window.fullscreen = (love.system.getOS() == "Android")
  screenWidth, screenHeight = love.graphics.getDimensions( )
  clearBoard()

  -- 36 high
  assets.textfont = love.graphics.newImageFont("assets/font.png", " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-.,?!")
  -- 32 high :: use an img font for a cheap sprite sheet. The letters are roughly how the shape looks
  assets.blockfont = love.graphics.newImageFont("assets/blockfont.png", " nu<>xXr7LJNUCD#")


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
  love.graphics.setColor(255, 200, 20, 255)
  love.graphics.print(currentTile.tile, bx + (currentTile.x * 32), by + (currentTile.y * 32))

  -- draw 'floor'
  love.graphics.setColor(40, 140, 80, 255)
  love.graphics.rectangle("fill", 0, by + (board.height * 32), screenWidth, 32)
  love.graphics.rectangle("fill", bx - 32, by, 32, screenHeight - (by*2) )
  love.graphics.rectangle("fill", bx + (board.width * 32), by, 32, screenHeight - (by*2) )

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

  if (time > stepTime) then
    time = time - stepTime
    currentTile.tile = '<'
    --dropTile()
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

function readInput()
  input.up = love.keyboard.isDown("up")
  input.down = love.keyboard.isDown("down")
  input.left = love.keyboard.isDown("left")
  input.right = love.keyboard.isDown("right")
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
  local src = {'n','u','<','>'}
  bag = shuffle(src)
end
