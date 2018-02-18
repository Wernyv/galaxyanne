pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--galaxyanne 0.91
--by wernyv

-----------------------------
-- tables -------------------

t_dnce={ -- dance frames
--x,y,s
 { 0, 0, 2},
 { 1,-1, 1},
 { 0, 0, 2},
 {-1,-1, 1},
}
t_coll={ -- collision pattern
 {-3,-3,4,4},-- annes
 {-3,-3,3,4},-- ship
 {-1,-4,1,1},-- enemy bullet |
 {-1,-1,1,1},-- enemy bullet *
 {-1, 0,1,4},-- players missile
}
t_sprite={ -- id,hflip,vflip,collisionrect
-- no l<->r u<->d
--1,2,3,4,c,
 -- in convoy
 {  6, 7, 4, 0, 1},-- ('-') stay 1
 {  0, 7, 4, 0, 1},-- |'-'| stay 2
 -- rotation 360/22.5
 { 70,10, 7, 0, 1},-- 3( =   90' fly
 { 64,10, 6, 0, 1},-- 4/'-'/ 67'
 { 38, 9, 5, 0, 1},-- 5/'-'/ 45'
 { 32, 7, 4, 0, 1},-- 6/'-'/ 22'
 {  6, 7, 4, 0, 1},-- 7|'-'|
 { 32, 7, 4, 2, 1},-- 8\'-'\ -22'
 { 38, 5, 5, 2, 1},-- 9\'-'\ -45'
 { 64, 4, 6, 2, 1},--10\'-'\ -67'
 { 70, 4, 7, 2, 1},--11 = )
 { 64, 4, 8, 3, 1},--12/,-,/ 
 { 38, 5, 9, 3, 1},--13/,-,/ -135'
 { 32, 7,10, 3, 1},--14/,-,/
 {  6, 7,10, 3, 1},--15|,-,| 180'
 { 32, 7,10, 1, 1},--16\,-,\ 
 { 38, 9, 9, 1, 1},--17\,-,\ 135' 
 { 64,10, 8, 1, 1},--18\,-,\ 
 { 70,10, 7, 0, 1},--19 ( =  90' fly
 -- no collision ver
 {  6, 7, 4, 0}, -- 20 |'-'|
 -- special
 { 96, 7, 7, 0},-- 21 24 hyde
 { 44, 7, 7, 0},-- 22 25 ball
 -- deads
 {128, 7, 7, 0},-- 23 21 dead 1
 {130, 7, 7, 0},-- 24 22 dead 2
 {132, 7, 7, 0},-- 25 23 dead 3
 -- ship
 { 14, 7,10, 0, 2},-- 26 ship
 {160, 7,10, 0},-- 27 miss1
 {162, 7,10, 0},-- 28 miss2
 {163, 7,10, 0},-- 29 miss3
 -- bullets (8x8)
 { 12, 0, 4, 0, 3},-- 30 bullet |
 { 28, 1, 2, 0, 4},-- 31 bullet *
 { 13, 0, 3, 0, 5},-- 32 misisle
 { -1, 8,13, 0, 2},-- 33 bubble
 { 46, 7,10, 0, 2},-- 34 ship(p)
 { 76, 9, 3, 0}, -- 35 x
}
ta_boom={
 { 10, 128, 7,7},
 { 15, 130, 7,7},
 { 20, 132, 7,7}}

music_={
 warpin=0,
 warpout=2,
 sydney0079=3,
 aces=8,
}
sfx_={
 shot=0,
 charge=1,
 hit=2,
 miss=3,
 begin=5,
 extend=6,
}

function putat(id,x,y,blink)
 local st = t_sprite[id]
 local sp = st[1]
 if sp>=0 then -- sprite
  local sz = 2 -- 16x16
  if blink>0 and fget(sp,2) then
   sp += blink*2
  end
  if fget(sp,0) then
   sz = 1 -- 8x8
  end
  spr(sp,x-st[2],y-st[3],sz,sz,st[4]>1,st[4]%2==1)
 else
  circ(x,y,st[2],st[3]) -- barrier
 end
end

function sprfr(x,y,tbl,frame)
 if frame>=tbl[#tbl][1] then
  return true
 end
 for i=1,#tbl do
  local t=tbl[i]
  if t[1]>frame then
   local sz=fget(t[2],0) and 1 or 2
   spr(t[2],x-t[3],y-t[3],sz,sz)
   break
  end
 end
 return false
end
-----------------------------
-- application entries ------

function _init()
 -- extract tables
 --t_dnce   = textract(t_dnce)
 --t_coll   = textract(t_coll)
 --t_sprite = textract(t_sprite)
 stages_init() -- set missing default
 scene=scenes.title:init()
 score=numsco:new()
 hiscore=numsco:new()
end

function _update()
 stars:update() -- bg
 scene:update() -- games
 hud:update()   -- fg
end

function _draw()
 cls()
 stars:draw()
 scene:draw()
 hud:draw()
-- debug_hud()
end

-----------------------------
-- globals ------------------
stage = nil
scene = nil

-- consts -------------------
oo={x=63.5,y=63.5} -- screen centre

-----------------------------
-- functions ----------------

function limabs(_v,_w) -- adjust v to -w<=v<=w
 return mid(-_w,_v,_w)
end

function near(v,t,m)
 return (t+abs(m)>=v and v>=t-abs(m))
end

function in_range(v,mn,mx)
 return (mn<=v and v<=mx)
end

function get_dir(from,to)
 -- right=0 up=0.25 left=0.5 
 local dx = to.x-from.x
 local dy = to.y-from.y
 return atan2(dx,dy)
end

function get_dist(x1,y1,x2,y2)
 return sqrt((x1-x2)^2+(y1-y2)^2)
end

function in_field(o)
 return in_range(o.x,0,127) and
        in_range(o.y,0,127)
end

function instance(class, obj)
 -- copy all key-value w/o 'new'
 local key
 local val
 for key,val in pairs(class) do
  if key!="new" then
   obj[key]=val
  end
 end
 return obj
end

function pals(p1,p2)
 local i
 for i=1,#p1 do
  pal(p1[i],p2[i])
 end
end
-----------------------------
-- anness -------------------

function an_rot_l(now)
 local r = now+1
 if r==19 then r=3 end
 return r
end

function an_rot_r(now)
 local r = now-1
 if r==2 then r=18 end
 return r
end

function an_rot_to(s,ang)
 local ts=3+flr((ang+(1/32))/(1/16))
 if s.s != ts then
  s.s += sgn(ts-s.s)
  return true
 else
  return false
 end
end

function an_rot_p(s)
 -- rotate to galaxip
 if(player.y > s.y)s.c+=1
 if s.c >= 5 then
  s.c=0
  local a = get_dir(s,player)
  an_rot_to(s,mid(0.55,a,0.95))
 end
end

function an_shot_rnd(s)
 local a=get_dir(s,player)+rnd(s.fw)-(s.fw/2)
 a = mid(0.75-s.fw/2, a, 0.75+s.fw/2)
 return enemies:fire_for(s.x,s.y,a,3)
end

function an_shot_thin(s)
  local v=limabs((player.x-s.x)/16,1)
  return enemies:fire_to(
      s.x, s.y,     -- src
      s.x+v, s.y,--+3, -- dst
      3)             -- spd/frame
end

an_zk2 = {
 col=11, -- lgreen
 p=3, -- score
 combo=1, -- combo ratio
 f=0, -- 0:convoy
      -- 1:turn-out
      -- 2:charge
      -- 3:turn-in
      -- 4:dead
      -- 5:cascade?
      -- 6:escape
      -- -1:lost
 m=0, -- mabataki
 s=1, -- sprite id
 c=0, -- animation counter
 -- for move
 x=0, y=0,
 vx=0,vy=1.5, -- xy speed for charge
 ax=0.1,  -- acceleration x
 ay=0,    -- accelaration y
 dx=0,    -- direction vx (1 or -1)
 maxvx=3,
 trnvx=0, -- abs(vx) need for turn
 mgn=8,   -- turn margin
 -- for fire
 fi  = 15, -- interval
 fr  =  6, -- fire rate
 fc  =  0, -- fi counter
 fa  = 3/36, -- trigger angle(/2)
 fw  = 0.1, -- fire width
 --------------------------------
 new=function(self,_i,_j)
  -- move on charging (sin)
  local obj={ i=_i, j=_j, idx=6*(_j-1)+_i }
  return instance(self,obj)
 end,
 --------------------------------
 update =function(s)
  -- blink
  if s.m>1 then
   s.m=(s.m+1)%9 --mb=2,3
  elseif rnd(100)<2 then --flr(rnd(100))==5 then
  -- assert(false)
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
  elseif s.f==3 then -- return to convoy
   s:_turnin()
   if s.f!=3 then
    enemies:returned()
   end 
  elseif s.f==4 then -- dead
   if s.c < 6 then
    s.s = 23 + flr(s.c/2)
   else
    enemies:dead(s)
   end  
   s.c += 1
  elseif s.f==6 then -- escape
   s:_escape()
   if s.f==-1 then -- escaped
    hud:lost(mid(s.x,0,107))
    enemies:escaped()
   end
  end
 end,

 _convoy =function(s)
  -- dance frame per i 
  local d=t_dnce[enemies.dance[s.i]]
  local wx=enemies.rests[s.j][s.i].x+d[1]
           +enemies.x
           -- +flr(enemies.x)
  local wy=enemies.rests[s.j][s.i].y+d[2]
  local ps=d[3]
  if stage.stocks and
   abs(s.y-wy)>2 then
   s.y+=2 --sgn(wy-s.y)*2
   s.s=22
   return
  end
  s.x=wx
  s.y=wy
  s.s=d[3]
  -- judge to charge
  if enemies.en_charge then
   local go = false
   if not enemies:exist(s.i,s.j-1) 
    and enemies.chg_cnt==0 
    and rnd(5)<1 -- flr(rnd(5))==3 -- 1/5
    then
    s.f=1 -- turn-out
    s.s=7 -- spr for #1
    s.c=0 -- turnout counter
   end
  end
 end,

 _turnout =function(s)
  s.c += 1 -- turnout
  if s.c%2==0 then
   if s.x <= 63 then -- leftside
    s.s = an_rot_l(s.s)
    s.x -= 4-abs(12-s.c)/3
    s.y -= (12-s.c)/2
   else              -- rightside
    s.s = an_rot_r(s.s)
    s.x += 4-abs(12-s.c)/3
    s.y -= (12-s.c)/2
   end
  end
  -- charge ?
  if s.s==15 then -- complete
   s.f =2 -- charge
   s.vx=0 -- x speed
   s.c =0 -- turnout counter
   s.lc=0 -- loop counter
   s.fc=0 -- ready to fire
  end
 end,

 _charge =function(s,nm)
  -- move
  if not nm then
   s:_chgmov()
   s.x = mid(-9,s.x,136)
  end
  -- state change
  if s.y>128+8 then -- loopback
   s.lc+=1
   if s.lc==3 then
    s.ax *= 1.5
   end
   --if s.lc>=3 then -- 3 loops
   -- s.f=-1 -- escaped
   if enemies.anum>4 or 
          not enemies.en_charge then
    s.f =  3 -- return
    s.y =-16 -- rewind y to top
    s.dx=  0
    s.s = 15 -- 
    s.c =  0 -- turnin counter
   else
    -- rewind top and x adjust
    s.y=-16
    s.x = mid(0,s.x,120)
   end
  end
  if s.lc>=3 and s.y>80 then -- escape
   s.f = 6 -- escape
  end
 end,

 _chgmov =function(s)
  if s.y<100 then
   if s.dx==0 or 
    abs(s.vx)>=s.trnvx and
    (s.x - player.x)*s.dx>=s.mgn then
     s.dx = sgn(player.x - s.x)
   end
  end
  s.vx = limabs(s.vx+s.ax*s.dx, s.maxvx)
  s.x+=s.vx
  s.y+=s.vy
  an_rot_p(s) -- rotate to player
 end,

 _fire =function(s)
  -- fire control (random)
  if(s.fc>0) return
  if not in_range(get_dir(s,player),
      0.75-s.fa,0.75+s.fa) then
   return
  end
  if rnd(100)<=s.fr and
     s.y<80 then
   if s:_setblt() then
    s.fc=s.fi
   end
  end
 end,

 _escape =function(s)
  if s.y<20 then
   s.f=-1
  end
  --s.vy+=k-0.2
  s.vx*=0.95
  s.x+=s.vx
  s.vy+=-0.4 --(s.vy>-8) and -0.2 or 0
  s.y+=s.vy
  an_rot_to(s,0.25) -- rotate to player
 end,

 --_setblt =an_shot_down,
 _setblt =an_shot_rnd, --thin,

 _turnin =function(s)
  local rpos=enemies:restpos(s.i,s.j)
  s.x=rpos.x+enemies.x
  s.y+=2
  if s.y>rpos.y-14 then
   if s.i<=3 then -- left
    s.s = an_rot_l(s.s)
   else           -- right
    s.s = an_rot_r(s.s)
   end
  end
  if s.y>=rpos.y then -- to formation
   s.y=rpos.y
   s.f=0
   s.s=7
  end
 end,

 draw =function(s)
  pal((s.ace and 4) or 8,s.col)
  putat(s.s,s.x,s.y,flr(s.m/3))
  if s.x<=-8 then
   spr(93,0,s.y-1) end
  if s.x>=127+8 then
   spr(93,128-8,s.y-1,1,1,true,false) end
  pal()
 end,

 hit =function(s)
  sfx(sfx_.hit,1) -- hit
  local b=s.p
  if s:ischg() then -- turn in
   enemies:rew_chg() -- rewind
   enemies:returned()
   --s.combo = 2^player.combo
   s.combo = player.combo
   b *= 4*s.combo
  end
  score:add(b)
  s.c=0 -- animation counter
  s.f=4 -- begin die sequence
 end,

 ischg =function(s)
  -- turn_out or charge or turn_in
  return 1<=s.f and s.f<=3
 end,
}

-------------------------------------
an_sim = {
-- super=an_zk2,
 -- type parameters
 col = 11, -- dark green
 p   = 1, -- score
 -- for mv_sin
 ax    = 0.1, -- vx accel
 maxvx = 2, -- max vx
 mgn   = 5, -- turn margin
 vy    = 1.5, -- charge vy
 -- fore fire
 fi    = 20,
 fr    = 5, -- fire rate
 fw    = 0,
 ---------------
 new = function(self,_i,_j)
  local obj = an_zk2:new(_i,_j)
  return instance(self,obj)
 end,
 ---------------
 draw = function(s)
  pals({4,5,6,14,15,7,9,10},
       {3,0,0,11,11,3,11,11})
  an_zk2.draw(s)
 end,
 _setblt =an_shot_rnd,
 --_setblt =an_shot_down,
}
-------------------------------------
an_zk1 = {
-- super=an_zk2,
 -- type parameters
 col = 3,  -- dgreen
 p   = 2,  -- score
 -- for fire
 fr  = 4, -- fire rate
 fw  = 0,

 _setblt = an_shot_rnd,
 --_setblt = an_shot_down,
 ----------------------
 new = function(self,_i,_j)
  local obj = an_zk2:new(_i,_j)
  --obj._ochg=obj._charge -- keep method
  return instance(self,obj)
 end,
 ----------------------
 _charge =function(s)
  if s.y<80 then
   s.ts = false
  end
  an_zk2._charge(s,s.ts)
  if not s.ts then
   local dd=abs(player.x-s.x)/
            abs(player.y-s.y)
   if in_field(s) and
      s.y>=80 and near(dd,1,0.2) then
    s.tx = 3 * sgn(player.x-s.x)
    s.ta = 0.75+0.125*sgn(s.tx)
    s.ts = 0 -- not nil
   end
  else
   if s.ts <= 10 then
    s.ts += 1
    an_rot_to(s,s.ta)
   else
    s.x += s.tx
    s.y += abs(s.tx) --s.vy --*1.5
   end
  end
 end
}

an_zg={
-- super=an_zk2,
 col = 12, -- lblue
 p   =  5, -- score
 -- for fire
 fi  =  5, -- interval
 fr  =  10,
 fa  =  40/360,
 -------------------------------
 new = function(self,_i,_j)
  local obj = an_zk2:new(_i,_j)
  return instance(self,obj)
 end,
 -------------------------------
 _convoy =function(s)
  an_zk2._convoy(s)
  s.s = 24
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
   s.f =2 -- charge
   s.vx=0
   s.c =0 -- turn counter
   s.lc=0 -- loop counter
   s.fc=0 -- ready to fire
  end
  if s.sqc<25 then
   s.s = 21 -- "
  elseif s.sqc<32 then
   s.s = 22 -- (_)
  else
   s.s = 2
  end
  s.sqc += 1
 end,

 _charge =function(s)
  an_zk2._charge(s)
  s.s = 1 -- keep '-'
  if s.y<0 and s.f==2 then
   -- cancel charge-loop
   s.f =  3 -- return
   s.y =-16 -- rewind y to top
   s.c =  0 -- turn counter
  end
 end,

 _setblt =function(s)
   return enemies:throw_for(
        s.x, s.y-5,  -- src
        sgn(player.x-s.x))  -- spd/frame
 end,

 _turnin =function(s)
  -- skip to convoy
  s.f = 0 -- convoy
 end,
}

an_gg={
 --super2=an_zg,
 col = 9,
 p = 10,
 fi = 30,
 fr = 5,
 bc = 0, -- barrier count
 -------------------------------
 new = function(self,_i,_j)
  local obj = an_zg:new(_i,_j)
  return instance(self,obj)
 end,
 _charge =function(s)
  an_zg._charge(s)
  s.bc = max(0,s.bc-1)
  if s.y>100 and
   enemies.en_charge then
   s.vy,s.vx = -4,0
  elseif s.y<30 and 
         s.vy<1.5 then
   s.vy += 0.5
  end
  if s.vy==0 then
   local a=get_dir(s,player)
   enemies:fire_for(s.x,s.y,
                a,4,4)
   s.bc=40
  end
 end,
 draw =function(s)
  an_zk2.draw(s)
  if s.bc==0 and s.s!=21 then
   circ(s.x,s.y+2,10,13)
   player:barrier(s.x,s.y+2,10)
  end
 end,
}

an_gf={
-- super=an_zk2,
 fi  = 4, -- fire interval
 col = 12, -- lblue
 p   = 4, -- score
 ax  = 0.15,
 fw  = 0.15, -- fire width
 ------------------------------
 new = function(self,_i,_j)
  local obj = an_zk2:new(_i,_j)
  obj.trnvx = obj.maxvx
  return instance(self,obj)
 end,

 _fire =function(s)
  -- fire control (random)
  if(s.fc>0 or s.y>80) return
  if abs(s.vx)<=0.6 then
   if s:_setblt() then
    s.fc=s.fi
   end
  end
 end,
}

an_ge={
-- super=an_zk2,
 p   = 5, -- score
 col = 13,
 ax  = 0.15,
 fr  = 15, -- fire rate
 tx  = nil, -- target-x
 -------------------------
 new = function(self,_i,_j)
  local obj = an_zk2:new(_i,_j)
  return instance(self,obj)
 end,
 -------------------------
 _chgmov =function(s)
  if s.vx==0 then
   s.tx = player.x +
     32*sgn(player.x-s.x)
   s.ax = abs(s.ax) *
     sgn(s.tx-s.x)
  end
  if s.tx and 
     abs(s.vx*s.vx/s.ax)/2 >
     abs(s.x-s.tx) then
   s.ax *=-1
   s.tx = nil
  end
  s.vx += s.ax
  if abs(s.vx)<abs(s.ax) then
   s.vx=0 end
  s.vx = limabs(s.vx,s.maxvx)
  s.x+=s.vx
  s.y+=s.vy
  an_rot_p(s) -- rotate to player
 end,
}

an_zk2s = {
-- super=an_zk2,
 col = 14, -- pink
 p = 10,
 -- for charge
 dgx = false, -- dodge status
 dgc = 3, -- dodge counter
 vy  = 1.5,  -- charge vy
 fr  = 10, -- fire rate
 -- special init
 f =1, -- turn-out
 vx=0, -- x speed
 c =0, -- turn counter
 lc=0, -- loop counter
 fc=0, -- ready to fire
 s =20,-- '-'(no col)
 ace =true,
 ----------------------
 new = function(self,_i,_j)
  -- inherit from type-zk
  local obj = an_zk2:new(_i,_j)
  obj._ochg = obj._charge
  obj._ochgmov = obj._chgmov
  obj.maxvx *=1.3
  obj.ax *=2
  return instance(self,obj)
 end,
 ----------------------
 _turnout =function(s)
  s.y -= 4
  if s.y <= -20 then
   s.x,s.y = 10,-20
   s.f = 2 -- charge
   s.s = 15 -- ,-,
  end
 end,
 _chgmov =function(s)
  s:_ochgmov() -- inherit
  local mx=player.mx
  local my=player.my
  local dx=mx-s.x
  if s.dgc>0 and 
    not s.dgx and
    in_range(my-s.y,10,20) and
    abs(dx)<10 then --and
   s.dgx = true
   s.vx = s.maxvx * sgn(-dx)
  end
  if s.dgx and my<s.y then
    s.gdx = false
    s.dgc -=1
  end
 end,
 _setblt =function(_s,_b)
  local v=limabs((player.x-_s.x)/16,3)
  enemies:fire_to(_s.x,_s.y,
          player.x,player.y,
          3,_b)
 end
}

an_dm ={
-- super=an_gf,
 -- special init
 f  =1, -- turn-out
 vx =0, -- x speed
 lc =-2, -- loop counter
 s  =20,-- '-'(no col)
 col=2, -- purple
 p = 12,
 ace=true,
 -------------------------
 new = function(self,_i,_j,pos)
  local obj = an_gf:new(_i,_j)
  obj._precharge = obj._charge
  obj = instance(self,obj)
  obj.pos = pos
  obj.y = 210 - obj.pos * 20
  obj.gaia = enemies.annes[1]
  return obj
 end,
 ----------------------
 _turnout =function(s) 
  s.y -= 4
  if(s.y > -20) return
  if s.pos==1 then
   s:_to_charge()
  elseif s.gaia.y==-60 then
   s:_to_charge()
  end
 end,
 _to_charge =function(s)
  s.f = 2 --> charge
  s.s = 15 -- ,-,
  if s.pos==1 then
   s.x = 64-30+rnd(60)
   --s.x = 64-30+flr(rnd(60))
  else
   s.x = s.gaia.x
  end
  s.y = -80 + s.pos*20
  s.fc=1000
 end,
 ----------------------
 _charge =function(s)
  local tbl = {0,16,-16}
  if s.pos>1 and s.gaia.f==-1 then
   s.fc=0
   s.maxvx=2
   s._charge = s._precharge
  end
  if s.y<40 then
   s.y += s.vy*2
  elseif s.y<44 then
   enemies:fire_to(s.x,s.y,
       player.x+tbl[s.pos],
       player.y, 3)
   s.y += s.vy*2
   s.vx = s.maxvx*sgn(rnd(2)-1)
  else
   local prey=s.y
   s:_precharge()
   if prey>s.y then
    s.f=1 --> turnout
   end
  end
 end,
}
gcount = 0
an_el= {
 x=63,
 y=40,
 vx=0,vy=0,
 ax=0,ay=0,
 tx=63,ty=0,
 ox=0,nx=0, --debug
 s=20,
 f=4,
 m=0,
 new = function(self,_i,_j,pos)
  local obj={ i=_i, j=_j, idx=6*(_j-1)+_i }
  return instance(self,obj)
 end,
 update = function(s)
  if player.mf!=0 and player.my>s.y and 
    mid(player.mx,s.x-5,s.x+5)==player.mx then
   s.tx = s.x + 20 * sgn(s.x - player.mx)
  end
  s:ease()
 end,
 draw = function(s)
  print(s.ttd,0,64)
  print("TX  "..s.tx,0,64+8)
  print("VX  "..s.vx,0,64+16)
  print("AX  "..s.ax,0,64+24)
  an_zk2.draw(s)
  print("OX  "..s.ox,0,64+32)
  print("NX  "..s.nx,0,64+40)
  print("GCNT"..player.mx,0,64+56)
 end,
 ease = function(s)
  -- p:position v:speed[pixel/frame] a:accela[pixel/frame^2] t:target-p
  -- TTS = v[current pix/frm] / a[<0 pix/(frm*frm)] [frame to v==0]
  -- TTD = v * TTS / 2 = (v^2 / a) / 2 = v^2 / 2a
  -- if TTD > t-p then a *= -1
  s.ax = sgn(s.tx - s.x) * 0.08
  if abs(s.x - s.tx) < 1.0 then
   s.tx = s.x
   s.ax = 0
   s.vx = 0
  else
   s.ttd = s.vx * s.vx / (2 * abs(s.ax))
   if s.ttd >= abs(s.x - s.tx) then
    s.ax *= -1
   end
  end
  s.ox = s.x
  s.vx += s.ax
  s.x += s.vx
  s.nx = s.x
 end,
 cntup = function(s)
  s.cnt = s.cnt+1
  --gcount += 1
 end
}
-------------------------------------
function collision(x1,y1,c1,x2,y2,c2)
 if c1==nil or c2==nil then
  return false
 end
 c1 = t_coll[c1]
 c2 = t_coll[c2]
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

ij2idx=function(i,j)
 return (j-1)*6+i
end

enemies={
 ---
 anum=0,          -- anne lives
 en_charge=false, -- enable charge
 chg_cnt=0,
 chg_num=0,
 annedead ={f=-1},
 dummyanne={f=-2}, -- 666
 dcnt=1,
 dance={1,2,3,4,1,2},
 dcnt=1, -- dance step cnt
 x=0,    -- convoy x offset
 vx=0.3, --0.2, -- x speed
 ---
 init=function(s)
  s.annes = {}
  -- init rest positions
  s.rests = {}
  for j=1,5 do
   rr={}
   for i=1,6 do
    rr[i] = { x=11+7+(i-1)*18,
              y= 8+7+(j-1)*14}
   end
   s.rests[j]=rr
  end
  -- init bullets
  s.bullets={}
  s.anum = 0
 end,
 ---
 reset=function(s)
  -- reset convoy status
  s.x=0   -- convoy x
  s.stop=nil
  s.en_charge=false -- disable charge
  s.annes={}
  s.anum=0
  s.boss = 1
  s.chg_int=stage[3]
  s.chg_cnt=stage[3]
  s.chg_num=0
  if stage.stocks then
   s.stidx = {0,0,0,0,0,0}
  end
  local sq = 1 -- sequencial
  local cv = stage[2] -- .types
  local fm = stage[1] -- .forms
  for j=1,#cv do
   for i=1,6 do
    sq=(j-1)*6+i
    if band(fm[j],0x40/(2^i))!=0 then
     local a = s:launch(cv[j],i,j)
     s.chg_num +=1
    else
     s.annes[sq] = s.dummyanne
    end
   end
  end
  s.bottom=#cv
 end,
 ---
 exist=function(s,i,j)
  if j<1 then
   return false -- over top
  end
  if s.annes[ij2idx(i,j)].f!=0 then
   return false -- dead or fly
  end
  return true -- exist
 end,
 ---
 charged =function(s)
  s.chg_num+=1
  s.chg_cnt=s.chg_int
  sfx(sfx_.charge,0)
  s.charge_snd=true
 end,
 ---
 escaped =function(s)
  s:returned()
  -- s.escnum +=1
  s:minus1()
  --s.anum   -=1
 end,
 ---
 returned=function(s)
  if s.chg_num > 0 then
   s.chg_num-=1
   if s.chg_num==0 then
    s.chg_cnt = s.chg_int/3
    if s.charge_snd then
     sfx(sfx_.charge,0,20)
     s.charge_snd=false
    end
   end
  end
 end,
 ---
 restpos=function(s,i,j)
  return s.rests[j][i]
 end,
 ---
 dead=function(s,a)
  if s.chg_int >= 5 then
   s.chg_int -= 1
  end
  print(a.combo,10,10)
  if a.combo>1 then
   hud:combo(a.x,a.y,a.combo)
  end
  a.f=-1 -- dead
  s:minus1()
  -- s.anum -=1
--[[
  if s.anum==0 then
   assert(false)
   if stage.boss!=nil then
    stage.boss()
   end
  end
--]]
--[[
  if stage.special!=nil then
   stage:special()
  end
--]]
 end,
 ---
 minus1=function(s)
  s.anum -=1
  if s.anum==0 and stage.boss and s.boss then
   s.boss=nil
   stage.boss()
  end
 end,
 ---
 rew_chg=function(s)
  s.chg_cnt = s.chg_int
 end,
 ---
 hitrect=function(s,x,y,c)
  for a in all(s.annes) do
   if a.f>=0 and a.y<120 then -- alive
    if collision(x,y,c,
        a.x,a.y,t_sprite[a.s][5]) then
     return a
    else -- convoy stop
     if a.f==0 and -- convoy
        y==mid(a.y+2,y,a.y-2) and -- same y
        --12<=abs(a.x-x) then -- near x
        sgn(x-a.x)==sgn(s.vx) and -- same side
        abs(x-a.x)<10 then -- near x
        s.stop = true
     end
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
   --if b.act then -- is active
    local sp = t_sprite[b.t+29]
    if b.t == 4 then -- barrier
     player:barrier(b.x,b.y,sp[2])
    else
     if collision(x,y,c1,b.x,b.y,sp[5]) then
      return true
     end
    end -- else
   --end
  end
  return false
 end,
 ---
 bullet=function(s,t,x,y,vx,vy,ax,ay,mx,my)
  b={}
  b.t = t -- type(spr,collision)
  b.x, b.y = x, y  -- locates
  b.vx,b.vy= vx,vy -- speeds
  b.ax,b.ay= ax,ay -- accels
  b.mx,b.my= mx,my -- max-speeds
  add(s.bullets,b)
  return b
 end,
 ---
 fire_to=function(s,x,y,tgx,tgy,spd)
  -- type 1: no accel, straight
  local dst = get_dist(tgx,tgy,x,y)
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
 fire_for=function(s,x,y,ang,spd,typ)
  typ = typ or 1
  -- type 3: fire angle(0:down 0.25:right)
  local vy = spd*sin(ang)
  local vx = spd*cos(ang)
  return s:bullet(typ,x,y,vx,vy,
           0,0,0,0)
 end,
 ---
 drop=function(s,idx)
  local t = idx+6
  while t <= s.bottom*6 do
   if s.annes[t].f>=0 then
    return
   end
   if s.annes[t].f==-1 then
    s.annes[t]=s.annes[idx]
    s.annes[t].j=flr((t-1)/6)+1
    s.annes[t].idx = t
    s.annes[idx]=s.annedead
   end
   t +=6
  end
 end,
 ---
 supply=function(s)
  for i,v in pairs(s.stidx) do
   if v<#stage.stocks then
    local j=0
    for p=i,s.bottom*6,6 do
     j +=1
     if s.annes[p].f>=0 then
      break
     end
     if s.annes[p].f==-1 then
      s.stidx[i]+=1
      s:launch(stage.stocks[s.stidx[i]],i,j)
      s.chg_num +=1
      break
     end
    end
   end
  end
 end,
 ---
 launch=function(s,t,i,j,noc)
  local p=t:new(i,j) 
  s.annes[ij2idx(i,j)]=p
  s.anum += 1
  p.s,p.f = 7,3 -- (,-,),turnin
  p.y = -10*p.y
  return p
 end,
 ---
 append=function(s,anne,pos)
  s.anum +=1
  s.annes[pos]=a
  s:charged()
 end,
 ---
 missed=function(s)
  s.pmissed=true
 end,
 ---
 update=function(s)
  if s.anum==0 and s:is_idle() then
   return
  end
  -- update all enemies
  imin=6
  imax=1
  for a in all(s.annes) do
   if a.f>=0 then -- active
    imin=min(imin,a.i)
    imax=max(imax,a.i)
    if s.pmissed and a.ace then
     a.lc = 3
    end
    if stage.stocks then
     s:drop(a.idx)
    end
    a:update()
   end
  end
  if stage.stocks then
   s:supply()
  end
  s.pmissed=false
  -- update all bullets
  for b in all(s.bullets) do
   --if b.act then -- is active
    b.x+=b.vx
    b.y+=b.vy
    b.vx += b.ax
    b.vy += b.ay
    if not in_field(b) then
     del(s.bullets,b)
     --b.act=false -- deactive
    end
   --end
  end
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
  if s.stop!=true then
   -- convoy wave
   s.x += s.vx
   if s.x<=-s.rests[1][imin].x+10 then
    s.vx = abs(s.vx)
   elseif s.x>=127-s.rests[1][imax].x-10 then
    s.vx = -abs(s.vx)
   end
  end
  -- charge interval
  s.chg_cnt = max(0, s.chg_cnt-1)
 end,
 ---
 draw=function(s)
  -- bullets
  for b in all(s.bullets) do
   --if b.act then -- active
    putat(29+b.t, b.x,b.y,0)
   --end
  end
  -- enemies
  for a in all(s.annes) do
   if a.f>=0 then 
    a:draw()
   end
  end
  --pal(8,8)
  --if s.stop!=nil then
  -- print("stop",64,64)
  --end
 end,
 ---
 is_clear=function(s)
  return s.anum==0
 end,
 ---
 is_idle =function(s)
  return (s.anum==0 or
         s.chg_num==0) and
         #s.bullets==0
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
  s.ext=500 --5000pts
 end,
 ---
 cmp =function(s,o)
  r = sgn(s.hi-o.hi)*2+sgn(s.lo-o.lo)
  return r
 end,
 ---
 add =function(s,p)
  if s.cs then
   return --counter stop
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
  if s.lo>=s.ext then
   s.ext*=2 --5000/10000/20000/...
   player:extend()
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
 x=0,
 y=0,
 ---
 init =function(s)
  s.rest=4
  s.crush=0
  s.combo=1
  s.mf=0 -- missile 0:rest 1:shot 2:reflect
 end,
 ---
 extend =function(s)
  s.rest +=1
  sfx(sfx_.extend,1)
 end,
 ---
 update =function(s)
  if s.y>119 then -- rollout
   s.y -= (s.y-118)/2
  end
  s.para = max(s.para-1,0) 
  -- crush check
  if s.crush==0 and 
     enemies:crushchk(s.x,s.y,t_sprite[26][5]) 
     then
    s.en_shot = false
    s.crush = 1
    s.combo = 1
    sfx(sfx_.miss,1) -- miss
    enemies:missed()
  end
  -- buttons
  if s.crush==0 and 
     s.para==0 then
   local dx = 0
   if btn(0) then
    dx = -2
   end
   if btn(1) then
    dx = 2
   end
   s.x = mid(5,s.x+dx,122)
  end
  if btn(5) then
   if s.en_shot  and -- enable 
      s.shot_release and 
      s.mf == 0 then -- shot
    sfx(sfx_.shot,1) --shot
    s.mx=s.x
    s.my=s.y-4
    s.mf=1
    s.shot_release = false
   end
  else
   s.shot_release = true
  end
  -- missile update
  if s.mf==1 then -- active
   s.my -= 4
   if s.my <= 0 then
    s.combo = 1
    s.mf=0 -- remove
   end
  end
  -- missile hitcheck
  if s.mf==1 then -- active
   local a=enemies:hitrect(s.mx,s.my,5)
   if a!=nil then -- hit
    s.mf=0
    a:hit()
    s.kills += 1
    s.combo = min(10, s.combo+1)
    if a.ace then
     s:extend()
    end
   end
  end
  if s.mf==0 then
   enemies.stop = nil
  end
 end,
 ---
 draw =function(s)
  -- ship
  if s.crush == 0 then
   if s.mf==0 then
    putat(32,s.x,s.y-4,0)
   end
   putat(s.para>0 and 34 or 26,
      s.x+s.para%2,s.y,0)
  else
   s.crush +=1 -- crush animation timer
   --sprfr(s.x,s.y,ta_boom,s.crush)
   if s.crush<24 then
    putat(27+flr(s.crush/8),
          s.x,s.y+s.crush/4,0)
   end
  end
  -- missile
  if s.mf>0 then
   putat(32,s.mx,s.my,0)
  end
 end,
 ---
 rollout =function(s)
  s.rest-=1
  s.x=63
  --s.y=118
  s.y=127+16
  --s.mx=-200
  --s.my=-200
  s.mf=0 -- missile rest
  s.en_shot = false
  s.shot_release= true
  s.crush = 0 
  s.kills = 0 -- kills w/o crush
  s.para = 0 -- paralized
 end,
 ---
 barrier =function(s,x,y,r)
  if not in_range(x,0,127) then
   return
  end
  local d = get_dist(s.x,s.y,x,y)
  if d<r+4 then
   s.para = 15
  end
  d = get_dist(s.mx,s.my,x,y)
  if d>=r and d<r+4 then
   s.mf=0 -- erased
  end
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
  return s.mf==0
 end,
}

-----------------------------
-- background ---------------

stars={ -- bg particles
 -- types
 flow = 1,
 grid = 2,
 storm= 3,
 -- operations
 init =function(s) -- generate 64
  s.pts={} -- particles
  for p=1,64 do
   s.pts[p]={x=rnd(127),
             y=rnd(140),
             v=(rnd(3)+1)/2,
             f=flr(rnd(20)),
             i=8+((p-1)%8)*16,
             j=flr((p-1)/8)*16,
             m=s.flow}
  end
  s.posy = 0 -- grid pos-x
  s.mode = s.flow -- stars
  s.next = s.mode
  s.stat = 0 -- not opening/closing
  s.count= 0
  s.sfrm = 0 -- for storm
 end,

 gradto =function(s,m)
  s.mode = m
 end,

 switchto =function(s,m)
  if s.next == m then
   return
  end
  s.next  = m -- next mode
  s.stat  = 1 -- closing
  s.count = 0 -- transition count
  if s.mode==stars.storm then
   music(music_.warpout)
  end
 end,

 _set_pts =function(s,mode)
  for p in all(s.pts) do
   p.m = mode
  end
 end,
 
 update =function(s)
  if s.stat!=0 then -- opening or closing
   if s.mode==stars.grid then
    s.count += 9
   elseif s.mode==stars.storm then
    --s.count += 4
   else
    s.count=149
   end
   s.count += 1
   if s.count>=150 then
    s.mode = s.next
    camera(0,0)
    s:_set_pts(s.mode)
    s.stat = s.stat==1 and 2 or 0
    s.count = 0
   end
  else
    s.count = 150
  end 
  -- rotate grid position
  s.posy +=1
  if s.posy>=128 then
   s.posy=0 end
  -- storm forces
  if s.stat==1 then -- not opening
   s.sfrm = 150-s.count
  else
   s.sfrm = s.count
  end
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
   if p.m==stars.storm then
    p.y+=(p.v*s.sfrm)/150
    if p.v>1 then   -- near
     p.x+=p.v/(151-s.sfrm)
     if p.x>127 then
      p.x=0
     end
    else            -- far
     p.x-=p.v/(151-s.sfrm)
     if p.x<0 then
      p.x=127
     end
    end 
   end
  end
 end,

 draw =function(s)
  if s.mode==stars.storm and 
     flr(rnd(151-s.sfrm))==0 then
   cls(1)
   if s.sfrm>120 then
    camera(rnd(3)-2,0)
   else -- delay charge
    enemies.chg_cnt+=1
   end
  end
  for i,p in pairs(s.pts) do
   if p.m==s.flow then
    color(6)
    if p.f<10 then
     pset(p.x,p.y) end
   elseif p.m==2 then
    pset(p.i,(s.posy+p.j)%128,3)
   elseif p.m==3 then
    if p.f<10 then
     line(p.x,p.y,
      p.x,p.y+p.v*5*s.sfrm/150,13)
    end 
   end
  end
  if s.mode==stars.grid and
   s.stat!=0 then
   for i=0,128*128-1 do
    if rnd(5)<=2 then
     pset(i%128,i/128,5)
    end
   end
  end
  --print("mode "..s.mode,0,20)
  --print("stat "..s.stat,0,30)
 end
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
combostr={
 new =function(s,_x,_y,_v)
  o ={x=_x, y=_y, v=_v, c=0, str="a",
      update=s.update, 
      draw=s.draw}
  return o
 end,
 update =function(s)
  if s.c==10 then s.str=nil
  else
   s.c+=1
   s.y-=0.5
  end
 end,
 draw =function(s)
  putat(35,s.x,s.y,0)
  print(s.v,s.x,s.y)
 end
}
hud={
 ccnt = 0, -- console counter
 csec = 0, -- console limit
 types={}, --nil,nil,nil,nil},
 xnns ={}, -- combos
 ---
 update =function(s)
  for i in all(s.types) do
    i:update()
    if not i.str then -- ==nil
     del(s.types, i)
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
  if player.combo>0 then
   putat(35,64,0,0)
   --print((2^player.combo),65,0)
   print(player.combo,65,0)
  end
  -- console string
  for t in all(s.types) do
    t:draw()
  end
  -- stage flags
  x=128-5
  snum = stagenum==nil and 0 or stagenum-1
  while snum>0 do
   if snum>=5 then
    snum -= 5
    sp = 92
   else
    snum -= 1
    sp = 77
   end
   spr(sp,x,120)
   x -= 5
  end
 end,
 ---
 console =function(s,str,x,y,sec)
  if str then
   add(s.types, typestr:new(str,x,y,sec,true,11))
  end
 end,
 ---
 caution =function(s)
  add(s.types, typestr:new("caution",-1,70,1.5,false,8))
 end,
 ---
 combo =function(s,x,y,v)
  add(s.types, combostr:new(x,y,v))
 end,
 ---
 lost =function(s,x)
  add(s.types, typestr:new("lost",x,10,1.5,false,11))
 end
}

-----------------------------
-- stages -------------------

function append_zk2s()
 a = an_zk2s:new(1,1)
 a.x = 127-player.x
 a.y = 140
 enemies:append(a,1)
 hud:caution()
 --music(music_.aces)
end

function append_dms()
 for i=1,3 do
  a = an_dm:new(1,1,i)
  a.x = rnd(100)+16
  enemies:append(a,i)
  a.gaia = enemies.annes[1]
 end
 hud:caution()
 --music(music_.aces)
end

function append_el()
 a = an_el:new(1,1)
 enemies:append(a,1)
 hud:caution()
end

function stages_init()
 for s in all(stages) do
  s.back = s.back or stars.flow
  s[3] = s[3] or 90 -- charge interval
 end
end

stages={
 { --stage 0 
  {0x1e,0x3f},
  {an_sim,an_sim}, 
  str="tuning", -- aaa
  back=stars.grid,
 },  
 { --stage 1 
  {0x08,0x21},
  {an_zk2,an_zk2},
  30,
  str="type:ann-z2",
 },
 { --stage 2 
  {0x1e,0x3f},
  {an_zk2,an_zk2},
  str="intercept",
 },
 { --stage 3 
  {0x12,0x21},
  {an_gf,an_gf},
  60,  -- 1.5s
  str="type:ann-gf",
 },
 { --stage 4 
  {0x12,0x3f,0x3f},
  {an_gf,an_zk2,an_zk2},
  str="evaluate",
  boss = append_zk2s,
 --[[
  special =function(s)
   if enemies.anum==0 and
      s.scnt==0 and
     player.kills>=0 then --5 then
     append_zk2s()
     s.scnt+=1
   end
  end,
 --]]
 },
 { --stage 5 
  {0x12,0x2a,0x15,0x2a},
  {an_zg,an_zg,an_zg,an_zg },
  45,
  str="corridor #1",
  back=stars.storm,
  entry =function(s)
   music(music_.warpin) -- warp in
  end,
 },
 { --stage 6 
  {0x11,0x20},
  {an_zk1,an_zk1},
  30,
  str="type:ann-z1",
 },
 { --stage 7 
  {0x1e,0x3f,0x3f},
  {an_zk1,an_gf,an_zk2}
 },
 { --stage 8 
  {0x1e,0x3f,0x3f},
  {an_gf,an_gf,an_zk2 },
  str="cascades",
  stocks={an_zk1,an_zk1},
 },
 { --stage 9 
  {0x21,0x21},
  {an_ge,an_ge},
  30,
  str="type:ann-ge",
 },
 { --stage 10 
  {0x1e,0x3f,0x3f},
  {an_ge,an_ge,an_ge},
  str="newtypes",
  boss = append_dms,
--[[
  special =function(s)
   if enemies.anum==0 and
      s.scnt==0 and 
      player.kills>=5 then
    append_dms()
    s.scnt+=3
   end
  end,
--]]
 },
 { --stage 11 
  {0x21,0x20,0x21,0x01},
  {an_zg,an_gg,an_zg,an_gg },
  str="corridor 2",
  40, -- charge interval init
  back=stars.storm,
  entry =function(s)
   music(music_.warpin) -- warp in
  end,
 },
 {  --stage 12
  {0x2a},--,0x15,0x2a,0x15,0x2a},
  {an_gf,an_gf,an_ge,an_zk1,an_zk1 },
  str="spars",
  --stocks={an_ge,an_ge},
  boss = append_el,
--[[
  special =function(s)
   if enemies.anum==0 then
    append_el()
   end
  end,
   --return false 
   --return stars.sfrm <= 0
  --if stars.sfrm>0 then
  --  return false end
  -- return true
  --end
--]]
 },
 -- stock
 -- accuracy
 -- dropout
 -- hypothesis
}

-----------------------------
-- scenes (status) ----------

scenes={

 title={
  init =function(s)
   stars:init()
   --bg = backs.stars:new()
   player:init()
   enemies:init()
   stage={}
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
    stagenum=1
    stage=stages[2]
    scene=scenes.stage:init()
   end
  end,
  ---
  draw =function(s)
   map(1,0,23,40,10,1)
   print("rev.0.91", 71,50)
   putat(32,64,70-4,0)
   putat(26,64,70,0)
   print("hit button to start",25,90)
  end,
 },
 
 stage={ -- stage # call
  init =function(s)
   s.timer=0
   s.subln=0
   s.reset=false
   player.en_shot=false
   enemies.en_charge=false
   stage = stages[stagenum]
   if stage.back!=nil then
    stars:switchto(stage.back)
   end
   --[[
   if stage.special!=nil then
    stage.scnt=0
   end
   --]]
   return s
  end,
  ---
  update =function(s)
   player:update()
   enemies:update()
   s.timer+=1
  end,
  ---
  draw =function(s)
   player:draw()
   enemies:draw()
   if stars.stat==0 then -- idle
    if enemies:is_clear() then
     enemies:reset()
     sfx(sfx_.begin,0)
     hud:console(stage.str,-1,90,3)
     s.reset = true
    end
    color(7)
    print("stage "..stagenum,50,72)
    if s.timer==60 then
     scene=scenes.play:init()
    end
   else
    s.timer = 0
   end
  end
 },
 
 play={
  init =function(s)
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
    scene=scenes.miss:init()
   elseif enemies:is_clear() then
    scene=scenes.clear:init()
   end
  end,
  ---
  draw =function(s)
   player:draw()
   enemies:draw()
  end
 },

 miss={
   init =function(s)
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
      scene = scenes.over:init()
     else
      player:rollout()
      if enemies:is_clear() then
       scene = scenes.clear:init()
      else
       scene = scenes.stage:init()
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
  init =function(s)
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
    if stagenum==#stages then
     scene =scenes.complete:init()
    elseif s.timer>30 then
     -- to nextstage
     stagenum += 1
     scene =scenes.stage:init()
     if stage.entry then
      stage:entry()
     end
    end
   end  
  end,
  ---
  draw =function(s)
   player:draw()
   enemies:draw() -- bullets
   if stage.clear then
    if not stage:clear() then
     s.timer -=1
    end
   end
  end
 },

 over={
   init =function(s)
    return s
   end,
   ---
   update =function(s)
    music(-1)
    enemies:update()
    if btn(5) then
     scene = scenes.title:init()
    end
   end,
   ---
   draw =function(s)
    enemies:draw()
    print("game over", 48,64,7)
   end
 },

 complete={
  init =function(s)
   return s
  end,
  update =function(s)
   --endanim
   if btn(5) then
    scene = scenes.title:init()
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
00044e5ff5f4400000044e5ffff440000004455ffff440000000444e5ff444400000444e5ff444400000444e5ff4444000044444444440000000003030000000
00044ffff5f4400000044ffff5f4400000044efff55440000000440ffff544400000440fffff44400000440fffff444000044e4444e44000000b0038300b0000
000440ffffe44000000440ffffe44000000440ffffe4400008044000ff56f44008044000ff5ff44008044000ff5ff440000444ffff444000003b0038b00b3000
00040000ff44000000040000ff44000000040000ff440000004400000fef4400004400000fef4400004400000fe54400000044800844000000b30b33b3033000
000400000044000000040000004400000004000000440000040800000044440004080000004444000408000000444400000004444440000000b00b31b300b000
004000000040000000400000004000000040000000400000000000000444400000000000044440000000000004444000000000800800000000b1bb3cb331b000
084800000400000008480000040000000848000004000000000000004440000000000000444000000000000044400000000000000000000000b8bb3cb338b000
004000008480000000400000848000000040000084800000000000844000000000000084400000000000008440000000000000000000000000b20b31b312b000
000000000400000000000000040000000000000004000000000000040000000000000004000000000000000400000000000000000000000000bb03b0330bb000
0000000000000000000000000000000000000000000000000000004080000000000000408000000000000040800000000000000000000000003bb03330b33000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003300000330000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444000000000044444400000000004444440000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000044444444400000004444444440000000444444444000000804444440000000080444444000000008044444400000000000000000000000000000000000
00080444fef4444400080444fef4444400080444e5f4444400004444444444400000444444444440000044444444444000000000aaa000000000000000000000
0044400ff55444440044400ff5f444440044400ff5f44444000008000fef4444000008000fef4444000008000e5f444400000707aaa000000000000000000000
0008000ffff444440008000ffff444440008000ffff4444400000000ff55444400000000ff5f444400000000ff5f444400000070a00000000000000000000000
00000000ffff444400000000ffff444400000000ffff444400000000ffff444400000000ffff444400000000ffff444400000707a00000000000000000000000
00000000ff55444400000000ff5f444400000000ff5f444400000000ffff444400000000ffff444400000000ffff444400000000080000000000000000000000
000000000eff4444000000000eff4444000000000e5f444400000000ff55444400000000ff5f444400000000ff5f444400000000880000000000000000000000
000000004444444000000000444444400000000044444440000008000fef4444000008000fef4444000008000e5f444400000000080000000000000000000000
000080444444400000008044444440000000804444444000000044444444444000004444444444400000444444444440aaaa0000000000000000000000000000
000444000000000000044400000000000004440000000000000008044444400000000804444440000000080444444000aaa00000000000000000000000000000
000080000000000000008000000000000000800000000000000000000000000000000000000000000000000000000000aa000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaa00000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa0000000000000000000000000000
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
0400040004000400040004000101000000000000000000000000000001010000040004000400040004000400000000000000000000000000000000000000000004000400040004000400040001000000000000000000000000000000000000000600060006000000000000000000000001000000000000000000000000000000
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
000100000c4703b4703947035470314702e4602946025460214501e4401b4401744013430104300d4300b42008420074200541003410034100241002410014100141001410014100141001510015700000000000
00090c0e35311303112c321283212532122311203111e3111c3111a31119311183111a312153110c3110831606370053701810018100181001810018100153001810018300153002140001400014000140000000
000100001777015570107700d5700c7700a5700a7700a5700f7701057016770175701d77022570287702b5702f770335703677038570397703757000000000000000000000000000000000000000000000000000
00020000376700b3703b6703b67010370153703c6703f670123703e6700f3703d6700a37036660093602966007360206600636021660033501c65001340146400153014630015200962001510056100260000000
00030014091100c1100e1100f110111101111011110101100f1100e1100b110091100611004110021100111001110011100211004110071100b1100c1100b1100a11009110071100411002110041100711009110
000c00002405325063240732607324073270732607328073260632806326053270532603328033270232802325013250132501326013260132600326003250032500323003230032300326003260032800329003
000b00002153223532215321f5321f5221f51224201242012420124201242010c2050e203102030c2030e200102000c200102001120013200060000d000150001f0001f0001f0001f0001f00021000210000b000
000900000160001610036200261003610046000362004610076200562007620086200a6200c62010630106401863019640216601f65027670286702f67035660356703e6703e6703e6703f6503e6703767024670
000500200d670346703c6703f6703e6603f6603f6603f6603f6603e6603a6503965037650336502f6502b64026640206401964018640126300d63007630026300a62001620066200162003610036100161002610
001000060b630086300a630096300a630086300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000060700a0700a07020070280703d0703e07037070200701f070130701607010070070702300023000230002300026000210001f000210001f0001d000210001f0001d000210001f0001d0002100023000
001400001072200703246131f00010722000001861300000107220000024613000001072200000186130000010722000002461300000107220000018613000001072200000246130000010722000031272218613
001400000c0001032510403130071332500000000001032500000103250030000000133250030000500103250e000103250e335103250c000133250c0000e3250c000153250c000133250c0000e0000e32512335
001400001372200104246130010413722001001861300100137220010024613001001372218613157222461315722007041861300704157220070424613007041572200704186130070415722246131372200004
001400000020513325002050020515325002050020510325002051732500205183251732500205153251332500205153251332515325002051532500205103250020515325002051032500205002050e32510325
01140000107222460310722246033c61510722007022460324613107222470224613007020070210722007020c7220c6030c6230c7020c722246130c7020f722246130f722246130f72213722246133c6150f722
001400000c61310325246130c205103250c2050c2050e3250c2050c3250c3250c2050e3250c205123350e3250c2050c3250c2050c2050f3350c205123250f335103250e335103251233513335153251732518335
00140000104350c605100031043510003000021043500002100021043510002000020e035100350e0350b0350c0350e0000e0000c0350e000100000c03500000000000c03500000000000c0350b0350c0350e035
001400001c0321c0321c0321703217200210001c0721c0721c07217072000000000000000000000000000000180701307013000130701300013070170701807017070180701a0000000018000000000000000000
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
00 4a424307
03 49424309
04 48424308
01 45460c0b
00 41420e0d
00 41420c0b
00 41420e0d
02 4142100f
03 41421144
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

