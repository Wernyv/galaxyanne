pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--galaxyanne 0.6
--by wernyv

-----------------------------
-- tables -------------------

t_dnce={ -- dance frames
       {x=0, y=0, s=2},-- 1
       {x=1, y=-1,s=1},-- 2
       {x=0, y=0, s=2},-- 3
       {x=-1,y=-1,s=1}}-- 4
t_sprid={ -- sprite id
   0, -- 1 ('-')
   6, -- 2 |'-'|
  32, -- 3 /'-'/ 22'
  38, -- 4 /'-'/ 45'
  64, -- 5 /'-'/ 67'
  70, -- 6 ( =   90'
  96, -- 7  ' '  hidden
  44, -- 8 (-) ball
 128, -- 9 dead1
 130, --10 dead2
 132, --11 dead3
  14, --12 ship
 160, --13 miss1
 162, --14 miss2
 163, --15 miss3
  12, --16 bullet1 |
  28, --17 bullet2 *
  13, --18 missile |
}
t_sprite={ -- id,hflip,vflip,colligionrect
-- no l<->r u<->d
 -- in convoy
 { 2, -7,-4, 0,0,c={-3,-3,4,4}},-- 1 || stay 1
 { 1, -7,-4, 0,0,c={-3,-3,4,4}},-- 2 () stay 2
 -- rotation 360/22.5
 { 6, -10,-7,0,0,c={-3,-3,4,4}},-- 3 <-  fly
 { 5, -10,-6,0,0,c={-3,-3,4,4}},-- 4
 { 4, -9,-5, 0,0,c={-3,-3,4,4}},-- 5 /
 { 3, -7,-4, 0,0,c={-3,-3,4,4}},-- 6
 { 2, -7,-4, 0,0,c={-3,-3,4,4}},-- 7 v v
 { 3, -7,-4, 1,0,c={-3,-3,4,4}},-- 8
 { 4, -5,-5, 1,0,c={-3,-3,4,4}},-- 9 \
 { 5, -4,-6, 1,0,c={-3,-3,4,4}},-- 10
 { 6, -4,-7, 1,0,c={-3,-3,4,4}},-- 11 ->
 { 5, -4,-8, 1,1,c={-3,-3,4,4}},-- 12
 { 4, -5,-9, 1,1,c={-3,-3,4,4}},-- 13 /
 { 3, -7,-10,1,1,c={-3,-3,4,4}},-- 14
 { 2, -7,-10,1,1,c={-3,-3,4,4}},-- 15 ^
 { 3, -7,-10,0,1,c={-3,-3,4,4}},-- 16
 { 4, -9,-9, 0,1,c={-3,-3,4,4}},-- 17 \
 { 5, -10,-8,0,1,c={-3,-3,4,4}},-- 18
 { 6, -10,-7,0,0,c={-3,-3,4,4}},-- 19 <-  fly
 -- deads
 { 9, -7,-7, 0,0},-- 20 dead 1
 {10, -7,-7, 0,0},-- 21 dead 2
 {11, -7,-7, 0,0},-- 22 dead 3
 -- special
 { 7, -7,-7, 0,0},-- 23 hyde
 { 8, -7,-7, 0,0},-- 24 ball
 -- ship
 {12,-7,-10, 0,0, c={-3,-3,3,4}},-- 25 ship
 {13,-7,-10, 0,0},-- 26 miss1
 {14,-7,-10, 0,0},-- 27 miss2
 {15,-7,-10, 0,0},-- 28 miss3
 -- bullets (8x8)
 {16,0,-4,   0,0, c={-1,-4,1,1}},-- 29 bullet |
 {17,-1,-2,  0,0, c={-1,-1,1,1}},-- 30 bullet *
 {18,0,-3,   0,0, c={-1,-3,1,0}} -- 32 misisle
}

function putat(id,x,y,blink)
 local st = t_sprite[id]
 local sp = t_sprid[st[1]]
 local sz = 2 -- 16x16
 if blink>0 and fget(sp,2) then
  sp += (blink)*2
 end
 if fget(sp,0) then
  sz = 1
 end
 spr(sp,x+st[2],y+st[3],sz,sz,st[4]==1,st[5]==1)
end
-----------------------------
-- application entries ------

function _init()
 scene=scenes.title:new()
 score=numsco:new()
 hiscore=numsco:new()
end

function _update()
 bg:update()
 scene:update()
 hud:update()
end

function _draw()
 cls()
 bg:draw()
 scene:draw()
 hud:draw()
 debug_hud()
end

-----------------------------
-- debug --------------------
debug=true
debug_rect=false

dprint_y=0
function dprint(str)
 print(str,0,dprint_y)
 dprint_y+=8
end

function debug_hud()
 if debug==nil then
  return
 end
 dprint_y=10
 color(11)
 dprint("enum:"..enemies.anum)
 dprint("chgn:"..enemies.charge_num)
 dprint("chgc:"..enemies.charge_cnt)
 dprint("scene:"..scene.name)
 dprint("kills:"..player.kills)
 dprint("sfrm:"..stars.sfrm)
 if d_dgs!=nil then
  dprint("dgs:"..d_dgs)
  dprint("dgc:"..d_dgc)
 end
 for b in all(enemies.bullets) do
  if b.a==true then
   dprint("bullet:x "..b.x)
   dprint("bullet:y "..b.y)
   break
  end
 end
 if debug_rect then
  color(12)
  rect(player.x+4,player.y+7,
       player.x+4+6,player.y+7+7)
 end
 color(8)
end

-----------------------------
-- globals ------------------

stage = nil
scene = nil

-----------------------------
-- anness -------------------

function turnleft(now)
 local r = now+1
 if r==19 then r=3 end
 return r
end

function turnright(now)
 local r = now-1
 if r==2 then r=18 end
 return r
end

function an_rot_p(s)
 -- rotate to galaxip
 if(player.y > s.y)s.c+=1
 if s.c >= 5 then
  s.c=0
  local t = 0
  local r = (player.x-s.x)/(player.y-s.y)
  if r<-2 then t=11
  elseif r<-0.5 then t=13
  elseif r<0.5  then t=15
  elseif r<2    then t=17
  else               t=19
  end
  if    (s.s>t) then s.s-=1
  elseif(s.s<t) then s.s+=1
  end
 end
end

anne_0 = { -- abstract
 new=function(self,_i,_j)
  -- move on charging (sin)
  local obj={ 
   i=_i,j=_j,
   x=0, y=0,
   vx=0,vy=0, -- xy speed for charge
   m=0, -- mabataki
   f=0, -- 0:convoy
        -- 1:turn-out
        -- 2:charge
        -- 3:return
        -- 4:dead
        -- -1
   s=1, -- sprite id
   p=1, -- point in convoy
   c=0, -- animation counter
   fi=20, -- fire interval
   fc=0,-- fi counter
   update=self.update,
   draw  =self.draw,
   hit   =self.hit,
   _convoy =self._convoy,
   _turnout=self._turnout, 
   _charge =self._charge,
   _chgmov =self._chgmov,
   _fire   =self._fire,
   _setblt =self._setblt,
   _turnin =self._turnin
  }
  return obj
 end,

 update =function(s)
  -- blink
  if s.m>1 then
   s.m=(s.m+1)%9 --mb=2,3
  elseif flr(rnd(100))==5 then
   s.m=3
  end
  -- fire interval count down
  if(s.fc>0) s.fc-=1
  if s.f==0 then -- convoy
   s:_convoy()
   if s.f==1 then -- begin charge
    enemies:charged()
   end
  elseif s.f==1 then -- turnout
   s:_turnout()
  elseif s.f==2 then -- charge
   -- move and rotate
   s:_charge()
   s:_fire()
   if s.f==-1 then -- escaped
    enemies:escaped()
   end
  elseif s.f==3 then -- return to convoy
   s:_turnin()
   if s.f!=3 then
    assert(enemies.charge_num>0)
    enemies:returned()
   end 
  elseif s.f==4 then -- dead
   s.s = 20 + flr(s.c/2)
   s.c += 1
   if s.c == 6 then
    enemies:dead(s)
   end  
  end
 end,

 _convoy =function(s)
  -- dance frame per i 
  local d=t_dnce[enemies.dance[s.i]]
  local wx=enemies.rests[s.j][s.i].x+d.x
           +flr(enemies.x)
  local wy=enemies.rests[s.j][s.i].y+d.y
  local ps=d.s
  s.x=wx
  s.y=wy
  s.s=d.s
  -- judge to charge
  if enemies.en_charge==true then
   local go = false
   if enemies:exist(s.i,s.j-1)==false 
    and enemies.charge_cnt==0 
    and flr(rnd(5))==3 -- 1/5
    then
    s.f=1 -- turn-out
    s.s=7 -- spr for #1
    s.c=0 -- turn counter
   end
  end
 end,

 _turnout =function(s)
  if s.c==0 then
   sfx(1,3)
  end
  s.c += 1
  if s.c%2==0 then
   if s.i <= 3 then -- leftside
    s.s = turnleft(s.s)
    s.x -= 4-flr(abs(12-s.c)/3)
    s.y -= flr((12-s.c)/2)
   else
    s.s = turnright(s.s)
    s.x += 4-flr(abs(12-s.c)/3)
    s.y -= flr((12-s.c)/2)
   end
  end
  -- charge ?
  if s.s==15 then -- complete
   s.f =2 -- charge
   s.vx=0 -- x speed
   s.c =0 -- turn counter
   s.l =0 -- loop counter
   s.fc=0 -- ready to fire
  end
 end,

 _charge =function(s)
  -- move
  s:_chgmov()
--  if s.y<100 then
--   if player.x+s.margn<s.x then
--    s.vx-=s.ax end
--   if s.x<player.x-s.margn then
--    s.vx+=s.ax end
--  end
--  if(s.vx<=-s.maxvx)s.vx=-s.maxvx
--  if(s.vx>= s.maxvx)s.vx=s.maxvx
--  s.x+=s.vx
--  s.y+=s.vy
--  an_rot_p(s) -- rotate to player
  -- state change
  if s.y>128 then -- loopback
   s.l+=1
   if s.l>=3 then -- 3 loops
    s.f=-1 -- escaped
   elseif enemies.anum>4 or 
          enemies.en_charge==false then
    s.f =  3 -- return
    s.y =-16 -- rewind y to top
    s.s = 15 -- 
    s.c =  0 -- turn counter
    s.dx=  0
   else
    -- rewind top and x adjust
    s.y=-16
    if s.x<0   then s.x=0 end
    if s.x>120 then s.x=120 end
   end
  end
 end,

 _chgmov =function(s)
  if s.y<100 then
   if player.x+s.margn<s.x then
    s.vx-=s.ax end
   if s.x<player.x-s.margn then
    s.vx+=s.ax end
  end
  if s.vx<=-s.maxvx then
   s.vx=-s.maxvx end
  if s.vx>= s.maxvx then
   s.vx=s.maxvx end
  s.x+=s.vx
  s.y+=s.vy
  an_rot_p(s) -- rotate to player
 end,

 _fire =function(s)
  -- fire control (random)
  if(s.fc>0)          return
  if(abs(player.x-s.x)>50)  return
  if flr(rnd(s.fr)) == 5 and
     s.y<80 then
   if s:_setblt()==true then
    s.fc=s.fi
   end
  end
 end,

 _setblt =function(s)
  return enemies:fire_to(
       s.x, s.y,  -- src
       s.x, s.y+10, -- dst
       3)           -- spd/frame
 end,

 _turnin =function(s)
  local rpos=enemies:restpos(s.i,s.j)
  s.x=rpos.x+flr(enemies.x)
  s.y+=2
  if s.y>rpos.y-14 then
   if s.i<=3 then -- left
    s.s = turnleft(s.s)
   else           -- right
    s.s = turnright(s.s)
   end
  end
  if s.y>=rpos.y then -- to formation
   s.y=rpos.y
   s.f=0
   s.s=7
  end
 end,

 draw =function(s)
  pal(8,s.col)
  putat(s.s,s.x,s.y,flr(s.m/3))
  if s.x<-8 then
   spr(93,0,s.y-1) end
  if s.x>128+8 then
   spr(93,128-8,s.y-1,1,1,true,false) end
 end,

 hit =function(s)
  sfx(2,2)
  local b=s.p
  if s.f==1 or   -- turn out 
     s.f==2 or   -- charge
     s.f==3 then -- turn in
   assert(enemies.charge_num>0)
   enemies:returned()
   b *= 4
  end
  score:add(b)
  s.c=0 -- animation counter
  s.f=4 -- begin die sequence
 end,
}

-------------------------------------
anne_sim = {
 new = function(self,_i,_j)
  local obj = anne_0:new(_i,_j)
  obj.typ = 1
  -- type parameters
  obj.col = 3 -- dark green
  obj.p   = 1 -- score
  -- for mv_sin
  obj.ax    = 0.1 -- vx accel
  obj.maxvx = 2 -- max vx
  obj.margn = 5 -- turn margin
  obj.vy    = 1.5 -- charge vy
  obj.dx    = 0
  -- fore fire
  obj.fr    = 10 -- fire rate
  obj.draw = self.draw
  return obj
 end,
 draw = function(s)
  pal(4,11)
  pal(5,0)
  pal(6,0)
  pal(14,3)
  pal(15,3)
  anne_0.draw(s)
  pal(4,4)
  pal(5,5)
  pal(6,6)
  pal(14,14)
  pal(15,15)
 end
}
-------------------------------------
function limabs(_v,_w)
 -- limit v to +w..-w
 if _v<-_w then
  return -_w end
 if _v>_w  then
  return _w  end
 return _v
end

anne_zk1 = {
 new = function(self,_i,_j)
  local obj = anne_0:new(_i,_j)
  obj.typ = 2
  -- type parameters
  obj.col = 3  -- dgreen
  obj.p   = 2  -- score
  -- for mv_sin
  obj.ax    = 0.1 -- vx step
  obj.maxvx = 3   -- max vx
  obj.margn = 8   -- turn margin
  obj.vy    = 1.5 -- charge vy
  obj.dx    = 0
  -- for fire
  obj.fi    = 10 -- interval
  obj.fr    = 15 -- fire rate
  return obj
 end,
}

anne_zk2 = {
 new = function(self,_i,_j)
  local obj = anne_zk1:new(_i,_j)
  obj.typ = 3
  obj.col = 11 -- lgreen
  obj.p   = 3  -- score
  -- for fire
  obj.fi  = 10 -- interval
  obj._setblt=self._setblt
  return obj
 end,

 _setblt =function(s)
  local v=limabs((player.x-s.x)/16,1)
  return enemies:fire_to(
      s.x, s.y,     -- src
      s.x+v, s.y+3, -- dst
      3)             -- spd/frame
 end
}

anne_zk2s = {
 new = function(self,_i,_j)
  -- inherit from type-zk
  local obj  = anne_zk2:new(_i,_j)
  obj._ochg  = obj._charge
  obj._charge = self._charge
  obj.col    = 14
  -- for charge
  obj.dgs = 0 -- dodge status
  obj.dgc = 3 -- dodge counter
  obj.vy  = 1.5  -- charge vy
  obj.fr  = 10 -- fire rate
  -- natural chager
  obj.f =2 -- charge
  obj.vx=0 -- x speed
  obj.c =0 -- turn counter
  obj.l =0 -- loop counter
  obj.fc=0 -- ready to fire
  obj._setblt=self._setblt
  return obj
 end,

 _charge =function(s)
  d_dgs=s.dgs
  d_dgc=s.dgc
  s:_ochg() -- inherit
  local mx=player.mx
  local my=player.my
  if s.dgs != 0 then
   s.x += s.dgs --special move
   if (mx<s.x 
      or s.x+16<mx) 
      and my<s.y then
    s.dgs = 0
    s.dgc -= 1
   end
  elseif s.dgc>0 and
   ((s.vx>0 and abs(s.x+16-mx)<=8)
   or 
   (s.vx<0 and abs(s.x-mx)<=8))
   then
   s.dgs = 2*sgn(s.vx) --s.vx*2/abs(s.vx)
  end
 end,

 _setblt =function(_s,_b)
  local v=limabs((player.x-_s.x)/16,3)
  enemies:fire_to(_s.x,_s.y,
          player.x,player.y,
          3,_b)
 end
}

anne_zg={
 new = function(self,_i,_j)
  local obj = anne_zk2:new(_i,_j)
  obj.typ =  5
  obj.col = 12 -- lblue
  obj.p   =  5 -- score
  -- for fire
  obj.fi  = 10 -- interval
  obj._convoy = self._convoy
  obj._turnout= self._turnout
  obj._charge = self._charge
  obj._turnin = self._turnin
  obj._setblt = self._setblt
  return obj
 end,

 _convoy =function(s)
  anne_0._convoy(s)
  s.s = 23
  s.x = -100
  s.y = -100
  s.sqc = 0 -- sequence cnt
 end,

 _turnout =function(s)
  if s.sqc==0 then -- begin
   s.x = rnd(100)+10
   s.y = 130
   s.sqx = (enemies.rests[s.j][s.i].x-s.x)/30
   s.sqy = (enemies.rests[s.j][s.i].y-s.y)/30
  elseif s.sqc<34 then
   s.y += s.sqy
   s.x += s.sqx
  else
   s.f = 2
   s.vx=0
   s.c =0 -- turn counter
   s.l =0 -- loop counter
   s.fc=0 -- ready to fire
  end
  if s.sqc<25 then
   s.s = 23 -- "
  elseif s.sqc<32 then
   s.s = 24 -- (_)
  else
   s.s = 2
  end
  s.sqc += 1
 end,

 _charge =function(s)
  anne_0._charge(s)
  s.s = 1 -- keep '-'
  if s.y<0 and s.f==2 then
   -- cancel charge-loop
   s.f =  3 -- return
   s.y =-16 -- rewind y to top
   s.c =  0 -- turn counter
   s.dx=  0
  end
 end,

 _setblt =function(s)
   return enemies:throw_for(
        s.x, s.y-5,  -- src
        sgn(player.x-s.x))  -- spd/frame
 end,

 _turnin =function(s)
  -- skip to convoy
  --assert(enemies.charge_num>0)
  --enemies:returned(s) 
  s.f = 0 -- convoy
 end,
}

anne_gf={
 new = function(self,_i,_j)
  local obj = anne_zk2:new(_i,_j)
  obj._chgmov = self._chgmov
  obj._fire = self._fire
  obj.fi  = 4 -- fire interval
  obj.typ = 6
  obj.col = 12 -- lblue
  obj.p   = 4 -- score
  obj.ax  = 0.15
  return obj
 end,

 _chgmov =function(s)
  if s.vx==0 then
   s.ax = abs(s.ax)*sgn(player.x-s.x)
  end
  if s.y<100 then
   if sgn(s.x-player.x)==sgn(s.vx) and
      abs(s.vx)>=s.maxvx then
    s.ax *= -1
   end
  end
  s.vx += s.ax
  if s.vx<=-s.maxvx then
   s.vx=-s.maxvx end
  if s.vx>= s.maxvx then
   s.vx=s.maxvx end
  s.x+=s.vx
  s.y+=s.vy
  an_rot_p(s) -- rotate to player
 end,

 _fire =function(s)
  -- fire control (random)
  if s.fc>0 or s.y>80 then
   return end
  if abs(s.vx)<=0.6 then
   if s:_setblt()==true then
    s.fc=s.fi
   end
  end
 end,
}

anne_ge={
 new = function(self,_i,_j)
  local obj = anne_zk2:new(_i,_j)
  obj._chgmov = self._chgmov
  --obj._fire = self._fire
  obj.fi  = 4 -- fire interval
  obj.typ = 7
  --obj.col = 12 -- lblue
  obj.p   = 5 -- score
  obj.ax  = 0.15
  obj.ox  = nil -- target-x
  return obj
 end,

 _chgmov =function(s)
  if s.vx==0 then
  end
 end,

}
-------------------------------------

anne_types={
  anne_sim,
  anne_zk1,
  anne_zk2,
  anne_zk2s,
  anne_zg,
  anne_gf,
  anne_ge,
}

function build_anne(n,i,j)
 if n!=0 then
  local p=anne_types[n]:new(i,j)
  return p
 end
end

function colligion(x1,y1,c1,x2,y2,c2)
 if c1==nil or c2==nil then
  return false
 end
 if x1+c1[1] <= x2+c2[3] and
    x2+c2[1] <= x1+c1[3] and
    y1+c1[2] <= y2+c2[4] and
    y2+c2[2] <= y1+c1[4] then
  return true
 end
 return false
end

-----------------------------
-- enemies ------------------

enemies={
 ---
 form={{1,1,1,1,1,1},  -- 1
       {0,1,1,1,1,0},  -- 2
       {0,0,1,1,0,0},  -- 3
       {0,1,0,0,1,0},  -- 4
       {0,1,0,1,0,1},  -- 5
       {1,0,1,0,1,0}}, -- 6
 anum=0,          -- anne lives
 en_charge=false, -- enable charge
 charge_cnt=0,
 charge_num=0,
 ---
 init=function(s)
  -- init rest positions
  s.rests = {}
  for j=1,4 do
   rr={}
   for i=1,6 do
    rr[i] = { x=11+7+(i-1)*18,
              y= 8+7+(j-1)*14}
   end
   s.rests[j]=rr
  end
  -- init bullets
  s.bullets={}
  for i=1,10 do
   s.bullets[i]={x=0,y=0,
                 vx=0,vy=0,
                 ac=0,ay=0,
                 mx=0,my=0,
                 a=false}
  end
  s.anum = 0
 end,
 ---
 reset=function(s)
  -- reset convoy status
  s.dance={1,2,3,4,1,2}
  s.dcnt=1 -- dance step cnt
  s.x=0   -- x position
  s.vx=0.2 -- x speed
  s.en_charge=false -- disable charge
  s.annes={}
  s.anum=0
  s.escnum=0 -- escaped num
  s.charge_int=stage.charge
  s.charge_cnt=stage.charge
  s.charge_num=0
  local sq = 1 -- sequencial
  local cv = stage.convoy.types
  local fm = stage.convoy.forms
  for j=1,#cv do
   for i=1,6 do
    local a =
       build_anne(cv[j],i,j)
    assert(cv[j]!=0)
    assert(a!=nil)
    if s.form[fm[j]][i]==1 then
     s.anum += 1
     a.s = 1 -- ('-')
     a.f = 0 -- convoy
     if stage.convoy.noc==nil then
      -- cancel fly-in
      a.y = -10*a.y
      a.s = 7 -- (,-,)
      a.f = 3 -- turn-in
      s:charged()
     end
    else
     a.f=-1 -- inactive
    end
    s.annes[sq] = a
    sq += 1
   end
  end
 end,
 ---
 exist=function(s,i,j)
  if j<1 then
   return false -- over top
  end
  if s.annes[6*(j-1)+i].f!=0 then
   return false -- dead or fly
  end
  return true -- exist
 end,
 ---
 charged =function(s)
  s.charge_num+=1
  s.charge_cnt=s.charge_int
  --sfx(1,3)
 end,
 ---
 escaped =function(s)
  s:returned()
  s.escnum +=1
  s.anum   -=1
 end,
 ---
 returned=function(s)
  s.charge_num-=1
  if s.charge_num==0 then
   sfx(-1,3)
  end
 end,
 ---
 restpos=function(s,i,j)
  return s.rests[j][i]
 end,
 ---
 dead=function(s,a)
  a.f=-1 -- dead
  s.anum -=1
  s.charge_cnt=s.charge_int
  if s.charge_int >= 5 then
   s.charge_int -= 1
  end
  if stage.speciial!=nil then
   stage:special()
  end
 end,
 ---
 hitrect=function(s,x,y,c)
  for a in all(s.annes) do
   if a.f!=-1 then -- alive
    if colligion(x,y,c,
 --       a.x,a.y,t_spr[a.s].c) then
        a.x,a.y,t_sprite[a.s].c) then
     return a
    end
   end
  end
  return nil
 end,
 ---
 crushchk=function(s,x,y,c1)
  -- vs annes
  if s:hitrect(x,y,c1)!=nil then
   return true
  end
  -- vs bullets
  for b in all(s.bullets) do
   if b.a then -- is active
    if colligion(x,y,c1,
        b.x,b.y,t_sprite[b.t+28].c) then
     return true
    end
   end
  end
  return false
 end,
 ---
 bullet=function(s,t,x,y,vx,vy,ax,ay,mx,my)
  for b in all(s.bullets) do
   if b.a==false then
    b.t = t -- type(spr,colligion)
    b.x, b.y = x, y
    b.vx,b.vy= vx,vy
    b.ax,b.ay= ax,ay
    b.mx,b.my= mx,my
    b.a=true
    return true
   end
  end
  return false -- empty
 end,
 ---
 fire_to=function(s,x,y,tgx,tgy,spd)
  -- type 1: no accel, straight
  local dst = sqrt(
         (tgx-x)^2 + (tgy-y)^2)
  return s:bullet(1,x,y,
           (tgx-x)*spd/dst,
           (tgy-y)*spd/dst,
           0,0,0,0)
 end,
 ---
 throw_for=function(s,x,y,vx)
  -- type 2: throw up
  return s:bullet(2,x,y,vx,-2,
                  0,0.2,0,3)
 end,
 ---
 append=function(s,anne)
  s.anum +=1
  s.annes[1]=a
  s:charged()
 end,
 ---
 update=function(s)
  -- dance frame
  s.dcnt=(s.dcnt+1)%10
  if s.dcnt==9 then
   for row=1,6 do
    s.dance[row]+=1
    if s.dance[row]==5 then
     s.dance[row]=1
    end
   end
  end
  -- update all enemies
  for a in all(s.annes) do
   if a.f != -1 then
    a:update()
   end
  end
  -- update all bullets
  for b in all(s.bullets) do
   if b.a==true then -- is active
    b.x+=b.vx
    b.y+=b.vy
    b.vx += b.ax
    b.vy += b.ay
    if b.y<0 or b.y>128 
    or b.x<0 or b.x>128 then
     b.a=false -- deactive
    end
   end
  end
  -- convoy wave
  s.x+=s.vx
  if s.x<=-10 then
   s.vx = abs(s.vx)
  elseif s.x>=10 then
   s.vx = -abs(s.vx)
  end
  if s.charge_cnt>0 then
   s.charge_cnt-=1
  end
 end,
 ---
 draw=function(s)
  -- bullets
  for b in all(s.bullets) do
   if b.a==true then -- active
    --spr(t_blt[b.t].s, b.x,b.y)
    putat(28+b.t, b.x,b.y,0)
   end
  end
  -- enemies
  for a in all(s.annes) do
   if a.f != -1 then 
    a:draw()
   end
  end
  pal(8,8)
 end,
 ---
 is_clear=function(s)
  return s.anum==0
 end,
 ---
 is_idle =function(s)
  local active = false
  for b in all(s.bullets) do
   if b.a==true then
    active=true
    break
   end
  end
  return (s.anum==0 or
         s.charge_num==0) and
         active==false
 end
}

-----------------------------
-- score --------------------

numsco={
 new =function(s)
  o={hi=0,lo=0,cs=false,md=true}
  o.add=s.add
  o.str=s.str
  o.reset=s.reset
  o.cmp=s.cmp -- sgn(s-o)
  return o
 end,
 ---
 reset =function(s)
  s.hi,s.lo = 0,0
  s.md=true
 end,
 ---
 cmp =function(s,o)
  r = sgn(s.hi-o.hi)*2+sgn(s.lo-o.lo)
  return r
 end,
 ---
 add =function(s,p)
  if s.cs then
   return
  end
  s.lo+=p
  if s.lo>9999 then
   s.hi+=1
   s.lo-=10000
   if s.hi>9 then
    s.hi=9
    s.lo=9999
    s.cs=true
   end
  elseif s.lo<0 then
   s.hi-=1
   s.lo+=10000
   if s.hi<0 then
    s.hi=0
    s.lo=0
   end
  end
  s.md=true
 end,
 ---
 str =function(s)
  if s.md then -- modified
   local st = ""..s.lo.."0"
   if s.hi>0 then
    s.st = ""..s.hi..sub("000",1,5-#st)..st
   else
    s.st = sub("    ",1,6-#st)..st
   end
   s.md=false
  end
  return s.st
 end,
}

-----------------------------
-- player -------------------

player={
 rest=0,
 kills=0,
 x=0,
 y=0,
 ---
 init =function(s)
  s.rest=4
  s.crush=0
 end,
 ---
 update =function(s)
  if s.y>118 then -- rollout
   s.y -= (s.y-118)/2
  end
  -- crush check
  --local x1=s.x+4
  --local y1=s.y+7
  --local x2=s.x+4+6
  --local y2=s.y+7+7
  --local col={4,7,4+6,7+7}
  if s.crush==0 and 
     --enemies:crushchk(x1,y1,x2,y2) 
     enemies:crushchk(s.x,s.y,t_sprite[25].c) 
     then
    s.en_shot = false
    s.crush = 1
    sfx(3,1)
  end
  -- buttons
  if s.crush==0 then
   if btn(0) then
    s.x-=2
    if s.x<5 then
     s.x=5
    end
   end
   if btn(1) then
    s.x+=2
    if s.x>122 then
     s.x=122
    end
   end
  end
  if btn(5) then
   if s.en_shot  and -- enable 
      s.shot_release and 
      s.mx<0  then -- shot
    sfx(0,1)
    s.mx=s.x
    s.my=s.y-4
    s.shot_release = false
   end
  else
   s.shot_release = true
  end
  -- missile update
  if s.mx>=0 then -- active
   s.my -= 4
   if s.my <= 0 then
    score:add(-1)
    s.mx=-200 -- remove
   end
  end
  -- missile hitcheck
  if s.mx>=0 then -- active
   local c = {-1,0,1,4}
   local a=enemies:hitrect(s.mx,s.my,c)
   if a!=nil then -- hit
    s.mx=-100
    a:hit()
    s.kills += 1
   end
  end
 end,
 ---
 draw =function(s)
  -- ship
  pal(8,8)
  if s.crush == 0 then
   if s.mx<0 then
   -- spr(96,s.x+7,s.y+2)
    putat(31,s.x,s.y-4,0)
   end
   --spr(14,s.x,s.y,2,2)
   putat(25,s.x,s.y,0)
  else
   s.crush +=1 -- crush animation timer
   if s.crush<5 then
    putat(26,s.x,s.y,0)
    putat(20,s.x,s.y,0)
   elseif s.crush<10 then
    putat(27,s.x,s.y,0)
    putat(21,s.x,s.y+2,0)
   elseif s.crush<15 then
    putat(28,s.x,s.y,0)
    putat(22,s.x,s.y+4,0)
   elseif s.crush<20 then
    putat(28,s.x,s.y,0)
   end
  end
  -- missile
  if s.mx>=0 then
   putat(31,s.mx,s.my,0)
   --spr(96,s.mx,s.my)
  end
 end,
 ---
 rollout =function(s)
  s.rest-=1
  s.x=63
  --s.y=118
  s.y=127+16
  s.mx=-200
  s.my=-200
  s.en_shot = false
  s.shot_release= true
  s.crush = 0 
  s.kills = 0 -- kills w/o crush
 end,
 ---
 is_empty =function(s)
  return s.rest<=1
 end,
 ---
 is_crush =function(s)
  return s.crush!=0
 end,
 ---
 is_idle =function(s)
  return s.mx<0
 end,
}

-----------------------------
-- background ---------------

stars={ -- bg particles
 init =function(s) -- generate 64
  s.pts={} -- particles
  for p=1,64 do
   s.pts[p]={x=flr(rnd(127)),
             y=flr(rnd(140)),
             v=(rnd(3)+1)/2,
             f=flr(rnd(20)),
             i=8+((p-1)%8)*16,
             j=flr((p-1)/8)*16,
             m=1}
  end
  s.posy = 0 -- grid pos-x
  s.mode = 1 -- stars
  assert(s.mode!=nil)
  s.sfrm = 0 -- for storm
  s.sfrv = 0 -- for storm
 end,

 gradto =function(s,m)
  s.mode = m
 end,

 switchto =function(s,m)
  s.mode = m
  for p in all(s.pts) do
   p.m = m
  end
  if m==3 then
   s.sfrm = 0
   s.sfrv = 1
  end
 end,

 update =function(s)
  -- grid position
  s.posy +=1
  if s.posy>=128 then
   s.posy=0 end
  -- storm forces
  s.sfrm+=s.sfrv
  if s.sfrm>150 then
   s.sfrm=150 end
  if s.sfrm<0 then
   s.sfrm=0 end
  -- particles
  for p in all(s.pts) do
   -- flow coord
   p.y+=p.v
   if p.y>127 then
    -- rewind and mode change
    p.y-=128
    p.m=s.mode
   end
   -- twincle
   p.f+=1
   if(p.f>20)p.f=0
   -- for mode:3(storm)
   if p.m==3 then
    p.y+=(p.v*s.sfrm)/150
    if p.v>1 then
     p.x+=p.v/(151-s.sfrm)
     if p.x>127 then
      p.x=0
     end
    else
     p.x-=p.v/(151-s.sfrm)
     if p.x<0 then
      p.x=127
     end
    end 
   end
  end
 end,

 draw =function(s)
  if s.mode==3 and 
     flr(rnd(151-s.sfrm))==0 then
   cls(1)
  end
  for i,p in pairs(s.pts) do
   if p.m==1 then
    color(6)
    if p.f<10 then
     pset(p.x,flr(p.y)) end
   elseif p.m==2 then
    color(3)
    pset(p.i,(s.posy+p.j)%128)
   elseif p.m==3 then
    color(13)
    if p.f<10 then
     line(p.x,p.y,
      p.x,p.y+p.v*5*s.sfrm/150)
    end 
   end
  end
 end
}

backs={
 stars={
  name="stars",
  ---
  new =function(s)
   stars:switchto(1)
   return s
  end,
  update =function(s)
   stars:update()
  end,
  draw =function(s)
   stars:draw()
  end,
 },
 training={
  name="training",
  ---
  new =function(s)
   stars:switchto(2)
   return s
  end,
  update =function(s)
   stars:update()
  end,
  draw =function(s)
   stars:draw()
  end
 },
 storm={
  name="storm",
  ---
  new =function(s)
   stars:switchto(3)
   return s
  end,
  update =function(s)
   stars:update()
  end,
  draw =function(s)
   stars:draw()
   if stars.sfrm>120 then
    camera(flr(rnd(3))-2,0)
   else -- delay charge
    enemies.charge_cnt+=1
   end
  end
 }
}

-----------------------------
-- foreground(hud) ----------

typestr={
 new =function(s,_str,_x,_y,_sec,_csr,_col)
  o={str=_str, sec=_sec, 
     x=_x, y=_y, csr=_csr, col=_col}
  if _x<0 then -- center
   o.x = 64-#_str*2 -- /2 *4
  end
  o.cnt=0
  o.update=s.update
  o.draw=s.draw
  return o
 end,
 update =function(s)
  if s.cnt>=s.sec*30 then
   s.str=nil
   return
  end
  s.cnt+=1
 end,
 draw =function(s)
  if s.str==nil then
   return
  end
  color(s.col)
  local len=s.cnt/2
  local str=sub(s.str,1,len)
  if s.csr and s.cnt%20<10 then
   str=str.."_"
  end
  print(str,s.x,s.y)
 end
}

hud={
 ccnt = 0, -- console counter
 csec = 0, -- console limit
 types={nil,nil,nil,nil},
 ---
 update =function(s)
  for i=1,#s.types do
   if s.types[i]!=nil then
    s.types[i]:update()
    if s.types[i].str==nil then
     s.types[i]=nil
    end
   end
  end
 end,
 ---
 draw =function(s)
  color(7)
  print(score:str(),0,0)
  if player.rest>=2 then
   for i=1,(player.rest-1) do
    spr(29,i*4-4,120)
   end
  end 
  -- console string
  for t in all(s.types) do
   if t!=nil then
    t:draw()
   end
  end
 end,
 ---
 console =function(s,str,x,y,sec)
  s.types[1]=
    typestr:new(str,x,y,sec,true,11)
 end
}

-----------------------------
-- stages -------------------

function append_zk2s()
 hud:console("special",0,60,5)
 a = anne_zk2s:new(1,1)
 a.x,a.y = 10,-20
 enemies:append(a)
end

stages={
 { -- [1]title screen
 },
 { str="stage 0",
  sub="simulation",
  convoy={types={1,1,1 },  -- type/line
          forms={4,1,1 }, -- form/line
          noc=1}, -- cancel fly-in
  charge=50, -- charge interval init
  back=backs.training,
  trn=1, -- noiz transition
  nxt=3
 },  
 { str="stage 1",
  sub="encount",
  convoy={types={3,2 },  -- type/line
          forms={2,1 }}, -- form/line
  charge=60, -- charge interval init
  back = backs.stars,
  trn=1, -- noiz transition
  nxt=4
 },
 { str="stage 2",
  convoy={types={6,3,2 },  -- type/line
          forms={4,1,1 }}, -- form/line
  charge=60, -- charge interval init
  back = backs.stars,
  special =function(s)
   if enemies.anum==1 and
      s.scnt==0 and
     player.kills>=15 then
     append_zk2s()
     s.scnt+=1
   end
  end,
  nxt=5
 },
 { str="stage 3",
  sub="jump",
  convoy={types={5,5,5 },  -- type/line
          forms={6,5,6 }}, -- form/line
  charge=50, -- charge interval init
  back = backs.storm,
  clear =function(s)
   stars.sfrv=-1
   if stars.sfrm>0 then
    return false end
   return true
  end,
  nxt=6
 },
 { str="stage 4",
  convoy={types={6,3,3 },  -- type/line
          forms={2,1,1 }}, -- form/line
  charge=40, -- charge interval init
  back = backs.stars,
  clear =function(s)
   stars.sfrv=-1
   if stars.sfrm>0 then
    return false end
   return true
  end
 }
}

-----------------------------
-- scenes (status) ----------

scenes={

 title={
  name="title",
  ---
  new =function(s)
   stars:init()
   bg = backs.stars:new()
   enemies:init()
   stage=stages[1]
   s.timer = 0
   return s
  end,
  ---
  update =function(s)
   if(s.timer<30)s.timer+=1
   if btn(5) and s.timer==30 then
    player:init()
    player:rollout()
    score:reset()
    stage=stages[2]
    scene=scenes.stage:new()
   end
  end,
  ---
  draw =function(s)
   map(1,0,23,50,10,1)
   print("   (rev.0.6)", 20,60)
  end,
 },
 
 stage={ -- stage # call
  name="stage",
  ---
  new =function(s)
   s.timer=0
   s.subln=0
   s.reset=false
   player.en_shot=false
   enemies.en_charge=false
   if enemies:is_clear() then
    enemies:reset()
    sfx(5,2)
    s.reset = true
   end
   if stage.back!=nil and
      stage.back.name != bg.name then
    bg = stage.back:new()
   end
   if stage.special!=nil then
    stage.scnt=0
   end
   return s
  end,
  ---
  update =function(s)
   player:update()
   enemies:update()
   if s.timer==0 and 
      s.reset    and
      stage.sub!=nil then
    hud:console(stage.sub,-1,90,3)
   end
   s.timer+=1
  end,
  ---
  draw =function(s)
   player:draw()
   enemies:draw()
   if s.reset and -- new stage 
      stage.trn==1 and -- noiz
      s.timer<5 then -- 1/65sec
    for i=0,128*128-1 do
     if rnd(5)<=2 then
      pset(i%128,i/128,5)
     end
    end
   end
   color(7)
   print(stage.str,50,72)
   if s.timer==60 then
    scene=scenes.play:new()
   end
  end
 },
 
 play={
  name="play",
  ---
  new =function(s)
   player.en_shot    = true
   enemies.en_charge = true
   -- missile,bullet init
   return s
  end,
  ---
  update =function(s)
   player:update()
   enemies:update()
   if player:is_crush() then
    scene=scenes.miss:new()
   elseif enemies:is_clear() then
    scene=scenes.clear:new()
   end
   if stage.special!=nil then
    stage:special()
   end
  end,
  ---
  draw =function(s)
   player:draw()
   enemies:draw()
  end
 },

 miss={
   name="miss",
   ---
   new =function(s)
    player.en_shot    = false
    enemies.en_charge = false
    s.timer=0
    return s
   end,
   ---
   update =function(s)
    s.timer +=1
    player:update()
    enemies:update()
    if player:is_idle() and
       enemies:is_idle() and
       s.timer > 60 then
     if player:is_empty() then
      scene = scenes.over:new()
     else
      player:rollout()
      if enemies:is_clear() then
       scene = scenes.clear:new()
      else
       scene = scenes.stage:new()
      end
     end
    end
   end,
   ---
   draw =function(s)
    player:draw()
    enemies:draw()
   end
 },

 clear={
  name="clear",
  ---
  new =function(s)
   s.timer = 0
   return s
  end,
  ---
  update =function(s)
   s.timer +=1
   player:update()
   enemies:update()
   if player:is_idle() and
      enemies:is_idle() then
    if stage.nxt==nil then
     scene =scenes.complete:new()
    elseif s.timer>30 then
     -- to nextstage
     stage =stages[stage.nxt]
     scene =scenes.stage:new()
    end
   end  
  end,
  ---
  draw =function(s)
   player:draw()
   enemies:draw() -- bullets
   if stage.clear!=nil then
    if stage:clear()==false then
     s.timer -=1
    end
   end
  end
 },

 over={
   name="over",
   ---
   new =function(s)
    return s
   end,
   ---
   update =function(s)
    enemies:update()
    if btn(5) then
     scene = scenes.title:new()
    end
   end,
   ---
   draw =function(s)
    enemies:draw()
    print("game over", 48,64)
   end
 },

 complete={
  name="complete",
  ---
  new =function(s)
   return s
  end,
  update =function(s)
   --endanim
   if btn(5) then
    scene = scenes.title:new()
   end
  end,
  ---
  draw =function(s)
   print("to be continued...",28,65)
  end
 }
}


__gfx__
000004444440000000000444444000000000044444400000000004444440000000000444444000000000044444400000e0000000a00000000000000000000000
000044444444000000004444444400000000444444440000000044444444000000004444444400000000444444440000e0000000a00000000000000000000000
000044444444000000004444444400000000444444440000000044444444000000004444444400000000444444440000e0000000900000000000000000000000
000444444444400000044444444440000004444444444000000444444444400000044444444440000004444444444000e0000000900000000000000000000000
00044f5ff5f4400000044ffffff4400000044ffffff4400000044f5ff5f4400000044ffffff4400000044ffffff4400070000000400000000000000000000000
00044e5ff5e4400000044e5ff5e440000004455ff554400000044e5ff5e4400000044e5ff5e440000004455ff5544000e0000000400000000000006060000000
00444ffffff4440000444ffffff4440000444effffe4440000044ffffff4400000044ffffff4400000044effffe4400000000000000000000007006860070000
004440ffff044400004440ffff044400004440ffff044400000440ffff044000000440ffff044000000440ffff04400000000000000000000067006870076000
00440000000044000044000000004400004400000000440000044000000440000004400000044000000440000004400002000000000000000076076676066000
0004080000804000000408000080400000040800008040000000400000040000000040000004000000004000000400002e200000000000000075076176057000
0000400000040000000040000004000000004000000400000000400000040000000040000004000000004000000400002720000000000000007d776c766d7000
0008040000408000000804000040800000080400004080000008480000848000000848000084800000084800008480002e200000000000000078776c76687000
00000000000000000000000000000000000000000000000000004000000400000000400000040000000040000004000002000000070000000072d76d76d27000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000766000000077567566577000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007c6000000067706660766000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000706000000006600000660000
00000444444000000000044444400000000004444440000000000000000000000000000000000000000000000000000000000444444000000000000000000000
00004444444400000000444444440000000044444444000000000000444400000000000044440000000000004444000000004444444400000000000000000000
00004444444440000000444444444000000044444444400000000044444440000000004444444000000000444444400000004444444400000000000000000000
00044444444440000004444444444000000444444444400000000444f444440000000444f444440000000444f444440000044444444440000000000000000000
00044f5f4444400000044fff4444400000044fff444440000000044f654444400000044fff44444000000445ff44444000044444444440000000000000000000
00044e5ff5f4400000044e5ffff440000004455ffff440000000444e5ff444400000444e5ff444400000444e5ff4444000044444444440000000000000000000
00044ffff5f4400000044ffff5f4400000044efff55440000000440ffff544400000440fffff44400000440fffff444000044e4444e440000000000000000000
000440ffffe44000000440ffffe44000000440ffffe4400008044000ff56f44008044000ff5ff44008044000ff5ff440000444ffff4440000000000000000000
00040000ff44000000040000ff44000000040000ff440000004400000fef4400004400000fef4400004400000fe5440000004480084400000000000000000000
00040000004400000004000000440000000400000044000004080000004444000408000000444400040800000044440000000444444000000000000000000000
00400000004000000040000000400000004000000040000000000000044440000000000004444000000000000444400000000080080000000000000000000000
08480000040000000848000004000000084800000400000000000000444000000000000044400000000000004440000000000000000000000000000000000000
00400000848000000040000084800000004000008480000000000084400000000000008440000000000000844000000000000000000000000000000000000000
00000000040000000000000004000000000000000400000000000004000000000000000400000000000000040000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000040800000000000004080000000000000408000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444000000000044444400000000004444440000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000044444444400000004444444440000000444444444000000804444440000000080444444000000008044444400000000000000000000000000000000000
00080444fef4444400080444fef4444400080444e5f4444400004444444444400000444444444440000044444444444000000000788000000000000000000000
0044400ff55444440044400ff5f444440044400ff5f44444000008000fef4444000008000fef4444000008000e5f444400000000788000000000000000000000
0008000ffff444440008000ffff444440008000ffff4444400000000ff55444400000000ff5f444400000000ff5f444400000000700000000000000000000000
00000000ffff444400000000ffff444400000000ffff444400000000ffff444400000000ffff444400000000ffff444400000000700000000000000000000000
00000000ff55444400000000ff5f444400000000ff5f444400000000ffff444400000000ffff444400000000ffff444400000000080000000000000000000000
000000000eff4444000000000eff4444000000000e5f444400000000ff55444400000000ff5f444400000000ff5f444400000000880000000000000000000000
000000004444444000000000444444400000000044444440000008000fef4444000008000fef4444000008000e5f444400000000080000000000000000000000
00008044444440000000804444444000000080444444400000004444444444400000444444444440000044444444444000000000000000000000000000000000
00044400000000000004440000000000000444000000000000000804444440000000080444444000000008044444400000000000000000000000000000000000
00008000000000000000800000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000c00c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000c00c000000000000c00c00000000000cc00cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000094000000c000c000c000c0000000000000000000000000024400000000000000000000000000000000000000
0000000090000000000000009a000000000000a00004000000000000000000000000000000000000000000044200000000000000440004999006660000000000
00000004990000000000000900a0000000077700000900000000000000000000000000000000000000000004f200000000000009008882000900006d00000000
00000000400000000007700400900000070000070000000000000000000000000000000000000000000000d404000000000000900800008220000d5d55000000
000ff0000000000000700700940000007700000700777000c000c000c000c000000000000000000000000d40064000000000040080000000088dd50d05500000
00f77f0000000000070000700077000000000000700007000000000000000000000000000000000000000f406d40000000000008000000000205d0d667500000
00f77f0000ff0000070000f00700700000000000f0000000000000000000000000000000000000000000f0d6650f000000000480050000000000000b67000000
000ff0000f77f00000f00000f0000700700aaaa4f000007000000008000000000000000000000000000f006dd500f00000000080dd6000000050005066700000
000000000f77f00000009440f000070070a0000000000070c000c000c000c000000000000000000000000d6656d000000000080010d00005005d00f566000000
0000444000ff0000000400040f007000000000000a0000000000000000000000000000000000000000000666665000000000080000d00000005d000000000000
00099944000000000090000040f70000000000000af70700000000000000000000000000000000000000d666665d00000000800000d6000005d0000000000000
000999940004400000900000400040000a0000000000a000000000000000000000000000000000000000dd6665dd000000008000101d00005500000000000000
000999940044990000a0000090400900090000000a000900c000c000c000c000000000000000000000000dddddd0000000002000000d00555000000000000000
0000999000099000000a000400900900000000000a00040000000000000000000000000000000000000040ddd000000000080000000100500606000000000000
00000000000000000000a9900009a00000900000a00a9000000000000000000000000000000000000004000000040000000800000101d0055d5d500000000000
00000000000000000000000000000000000944090000000000000000000000000000000000000000000400000004000000020400000050000d0d5f0000000000
0000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000080000000101d1ddd6610f000000000
0000000000000000000000070000000000070060000000000000000000000000000000000000000000000000000000000020090000100111111d609500000000
00000000000000000000007600000000700060000000007000000000000000000000000000000000000000000000000000000040001100015000d00050000000
00000007060000000070007200000000000000000070765000000000000000000000000000000000000000024200000000800090000100150000000050000000
000000072600000000000660000000000000020000000700000000000000000000000000000000000000000444000000020000900001015000000005d0000000
00000072260000000000002000000700000260000000026000000000000000000000000000000000000000d4f4d0000000000090000111d11515105055000000
0000000267000000000000000700007067000006000000500000000000000000000000000000000000000f4654d500000200000900001d111511110005000000
0066000020000000006600002000770000000000000d000000000000000000000000000000000000000ff556645f00000000000900000d0001500d00055d0000
0726006d6d000070072000606d00007000000060000000000000000000000000000000000000000000005d6dd6d5f0002000000400000000000005d000675d50
7276000c0070072706000000007000270600000000200000000000000000000000000000000000000000d666666d000000000000000000000000005d0d655500
7260007c0600722600000000060000005000000000000000000000000000000000000000000000000000d66666dd0000000000040000000060000005dd05000d
002006656d0002600020060000000000002006000007000000000000000000000000000000000000000000666d000000000000000000000060000000dd001160
026066d56507260002006000000700000000000000000070000000000000000000000000000000000000040000200000000000400000000dd00000000dd15600
726606016072600072060000007200007206000006007000000000000000000000000000000000000000000000400000000000000001550006d6000001d6d000
7550000d006550007000000d006550007500060000000200000000000000000000000000000000000000000000000000000400005551050000055d6d00dd0000
06000000000000000600000000000000050000000d00055000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000888880008880008800000088000880
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008800000088088008800000088808880
000000000000000000000000000000000000bbb00000000000000bbb0000000000000bbb00000000000003333333000088000000080008008800000008808800
00000000000000000000000000000000000bbbbb000000000000bbbbb00000000000bbbbb000000000033bbb3bbb300088000880880008808800000000888000
0000000000000000000000000000000000033bbb00000000000033bbb0000000000033bbb00000000033b303b0bb330088000880888888808800000008888800
0000000000000000000000000000000000033bbb00000000000033bbb0000000000033bbb0000000003bbbb0b303330008800880880008808800000088808880
0000000000000000000000000000000000003bb000000000000033bb00000000000033bb0000000003bb30b0b0b3330000888880880008808888888088000880
000000000000000000000000000000000000bb000000000000000bb00000000000000bb00000000003bb0b033b33b30000000000000000000000000000000000
000000000000000000000000000000000000b0330000000000000b033000000000000b03300000000033333b0b30000088008800880008808888888000000000
00000000000000000000000000000000000003333000000000000033330000000000003333000000000000333003300088008800888008808800000000000000
00000000000000000000000000000000300b33333000000003000b333300000000030b0333000000000000000333b00008008000888808808800000000000000
0000000000000000000000000000000003000303b00000000030b0303b00000000030b030b0000000000000003bb300008888000888888808888880000000000
00000000000000000000000000000000003030333000000000030303330000000000303033000000000000000033000000880000880888808800000000000000
0000000000000000000000000000000000030b3330000000000030b333000000000003b33300000000000000000b000000880000880088808800000000000000
00000000000000000000000000000000000000b3bb000000000000b3bbb00000000000b3bbb00000000000000000b00000880000880008808888888000000000
00000000000000000000000000000000000000bbb0b000000000000bb0bb00000000000bb0bb0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000bb1330b000000033bb1330b000000003bb0330b00000000000b300000000000000000000000000000000000000
00000000000000000000000000000000000030bb33330000003300bb3330000000003bbb33330000000000bbb330000000000000000000000000000000000000
0000000000000000000000000000000000030bbb0333300000000bbb0333000000030bb0333300000000bbbbb333000000000000000000000000000000000000
0000000000000000000000000000000000300bbb0333330000000bbb0333300000000bb033333000000bbbbbb333300000000000000000000000000000000000
0000000000000000000000000000000000000bbb0333330000000bb0333330000000bbb033333000000bbbbbb333300000000000000000000000000000000000
0000000000000000000000000000000000000bbb033333300000bbb0333333000000bb0333333300000bbbbbb333300000000000000000000000000000000000
0000000000000000000000000000000000000bb0333333300000bb03333333000000bb0333333300000bbbbbb333300000000000000000000000000000000000
00000000000000000000000000000000000000033333330000000033333333000000003333333300000bbbbbb333300000000000000000000000000000000000
00000000000000000000000000000000000003333333000000003333333300000000333333330000000bbbbbb333300000000000000000000000000000000000
00000000000000000000000000000000000003333300000000003333330000000000333333000000000bbbbbb333300000000000000000000000000000000000
00000000000000000000000000000000000000000030000000000000000000000000000000000000000bbbbbb333300000000000000000000000000000000000
0000000000000000000000000000000000000003000b0000000000030b0000000000000330000000000bbbbbb333300000000000000000000000000000000000
000000000000000000000000000000000000000b0000b0000000000b03b000000000000b0b000000000bbbbbb333300000000000000000000000000000000000
000000000000000000000000000000000000000b00003b000000000b00bb00000000000b3b000000000bbbbbb333300000000000000000000000000000000000
000000000000000000000000000000000000003b0000bb000000003b03b000000000003b3b00000000000bbbb333000000000000000000000000000000000000
0000000000000000000000000000000000000bbb000bb00000000bbb0b00000000000bbb000000000000000bb330000000000000000000000000000000000000
__gff__
0400040004000400040004000101000000000000000000000000000001010000040004000400040004000400000000000000000000000000000000000000000004000400040004000400040000000000000000000000000000000000000000000600060006000000000000000000000000000000000000000000000000000000
0200020002000000000000000000000000000000000000000000000000000000020002000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
00cccdcecdcfdccdddddde000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e2cee2e2e2e2e2e2e2e2e2e2e2e2e2e2e0e0e0e0e0e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cdb1b0e2e2e2e2e200b0b100b0b0e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e2cfe2e2e2e2e2e200000000000000e200808182830000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e2dce2e2e2e2e2e200000000000000e200909192930000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b0e2e2e2e2e2e2e2e2e2e2e2e2e20000a0a1a2a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000b0b1000000e2e2e2e2e200b0b10000b0b1b2b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003d4703b4703947035470314702e4602946025460214501e4401b4401744013430104300d4300b42008420074200541003410034100241002410014100141001410014100141001510015700000000000
00090c0e35311303112c321283212532122311203111e3111c3111a31119311183111a312153110c3110831606370053701810018100181001810018100153001810018300153002140001400014000140000000
000100001777015570107700d5700c7700a5700a7700a5700f7701057016770175701d77022570287702b5702f770335703677038570397703757000000000000000000000000000000000000000000000000000
00020000376700b3703b6703b67010370153703c6703f670123703e6700f3703d6700a37036660093602966007360206600636021660033501c65001340146400153014630015200962001510056100260000000
00030014091100c1100e1100f110111101111011110101100f1100e1100b110091100611004110021100111001110011100211004110071100b1100c1100b1100a11009110071100411002110041100711009110
000c00002405325063240732607324073270732607328073260632806326053270532603328033270232802325013250132501326013260132600326003250032500323003230032300326003260032800329003
000b00002153223532215321f5321f5221f51224201242012420124201242010c2050e203102030c2030e200102000c200102001120013200060000d000150001f0001f0001f0001f0001f00021000210000b000
00070308316201b600256200461003610026100361001610316100160017610066000761001600016001160018600186000160021600000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000e000023070230702307023070230702307023070230702307023070230702307023070230702307023070230702307023070210701f070210701f0701d070210701f0701d070210701f0701d0702107023070
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 05064344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

