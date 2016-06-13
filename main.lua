local screenWidth, screenHeight
local assets = {textfont, blockfont}

local playBoard = {} -- grid of blocks
local direction = ""

function love.load()
  love.window.fullscreen = (love.system.getOS() == "Android")

  -- 36 high
  assets.textfont = love.graphics.newImageFont("assets/font.png", " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-.,?!")
  -- 32 high :: use an img font for a cheap sprite sheet. The letters are roughly how the shape looks
  assets.blockfont = love.graphics.newImageFont("assets/blockfont.png", " nu<>xXr7LJNUCD#")


end

-- Update, with frame time in fractional seconds
function love.update(dt)

end

-- Draw a frame
function love.draw()
  love.graphics.setFont(assets.textfont)
  love.graphics.setColor(255, 200, 230, 255)
  love.graphics.print("EACH TILE HAS SOME OPEN EDGES - EXCEPT BLANK", 30, 178)
  love.graphics.print("WHEN A SET OF TILES HAS EVERY OPEN EDGE MATCHED", 30, 216)
  love.graphics.print("TO ANOTHER, THAT SET IN COMPLETE. THE TILES ARE", 30, 254)
  love.graphics.print("REMOVED AND ALL TILES ABOVE DROP DOWN.", 30, 292)
  love.graphics.print("GENERALLY IT PLAYS LIKE TETRIS, BUT WITH ONE", 30, 330)
  love.graphics.print("SQUARE AT A TIME AND DIFFERENT REMOVAL RULES!", 30, 368)


  love.graphics.print("7 COMPLETED SHAPES", 400, 64) -- only uppercase!
  love.graphics.print("INCOMPLETE SHAPES", 400, 464) -- only uppercase!

  -- quick test of block font spacing
  love.graphics.setFont(assets.blockfont)
  love.graphics.setColor(255, 200, 230, 255)
  love.graphics.print("r7<xx> n", 32, 32)
  love.graphics.print("LJ <>n X", 32, 64)
  love.graphics.print("<###>u u", 32, 96)

  love.graphics.print(" x  # L", 32, 432)
  love.graphics.print("> r>XL#", 32, 464)
  love.graphics.print("> x> un", 32, 496)
end

function love.keypressed(key)
  if key == 'escape' then love.event.quit() end
  -- figure out new direction
end

function love.keyreleased(key)
  -- remove direction
end
