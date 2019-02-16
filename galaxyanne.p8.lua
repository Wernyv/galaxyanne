pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
--galaxyanne 0.01r
--by wernyv

-- redef
function int(n) return flr(abs(n))*sgn(n) end
function rup(n) return flr(abs(n)+0.5)*sgn(n) end
function sgz(n) return (n==0) and 0 or sgn(n) end

-- oo util
function override(obj, class)
 local k,v
 for k,v in pairs(class) do
  obj[k]=v
 end
 return obj
end
function underride(obj, class)
 local k,v
 for k,v in pairs(class) do
  if not obj[k] then obj[k]=v end
 end
 return obj
end
function cont(v,l)
 if type(l)!="table" then
  return v==l
 end
 for a in all(l) do
  if v==a then
   return true
  end
 end
end

-- timer util
function tini(s)
 s._fc=_fcnt
end
function tcnt(s)
 return _fcnt-s._fc
end

-- debug log
function dlog(str)
 --printh(str,"log.txt")
end

sfx_={
 shot=0,
 charge=1,
 hit=2,
 miss=3,
 begin=5,
 extend=6,
}

sprites = {
 { 0,  -7, -4,  -3,-3,4,4 },
 { 6,  -7, -4,  -3,-3,4,4 }, -- |
 {32,  -7, -4,  -3,-3,4,4 },
 {38,  -9, -5,  -3,-3,4,4 }, -- /
 {64, -10, -6,  -3,-3,4,4 },
 {70, -10, -7,  -3,-3,4,4 }, -- -
 {14,  -7,-11,  -4,-3,4,0 }, --player
 {13,   0, -2,  -1,-2,1,3 }, --missile
 {12,   0, -4,  -1,-2,1,3 }, --bullet |
 {128, -7, -7,  0,0,0,0},
}

spr0 = {
 x=0, y=0, sp=1, mo=0, _c=0,
 new=function(s)
  return override({},s)
 end,
 upd=function(s)
--  lasts=s
  s.x+=s.vx
  s.y+=s.vy
  s._c=(s._c+1)%255
 end,
 drw=function(s)
  local sp = sprites[s.sp]
  local dx = sp[2]
  local dy = sp[3]
  if s.sh then dx=-15-dx end
  if s.sv then dy=-15-dy end
  local sz = fget(sp[1],0) and 1 or 2
  local mo = s.mo and s.mo*sz or 0
  if s.pl then
   for p in all(s.pl) do
    pal(flr(p/16),p%16)
   end
  end
  spr(sp[1]+mo, rup(s.x+dx),rup(s.y+dy), sz,sz, s.sh, s.sv)
  pal()
  --color(11)
  --rect(s.x+sp[4],s.y+sp[5],s.x+sp[6],s.y+sp[7])
 end,
 hit=function(s,o)
  local p1,p2=sprites[s.sp],sprites[o.sp]
  -- [4]xl [6]xr  [5]yu [7]yd
  if s.en!=false and o.en!=false then
   local gx=min(o.x+p2[6]-s.x-p1[4],s.x+p1[6]-o.x-p2[4])
   local gy=min(o.y+p2[7]-s.y-p1[5],s.y+p1[7]-o.y-p2[5])
   --[[
   s.x+p1[4] <= o.x+p2[6] and
   o.x+p2[4] <= s.x+p1[6] and
   s.y+p1[5] <= o.y+p2[7] and
   o.y+p2[5] <= s.y+p1[7] then
   ]]
   if gx>=0 and gy>=0 then
    return true
   elseif gy>=0 then
    _gpx=gx
   end
  end
  return false
 end,
 dist=function(s,o)
  return sqrt((s.x-o.x)^2+(s.y-o.y)^2)
 end,
}

ship = {
 x=64, y=119,
 vx=0, vy=-3,
 sp=7,
 ini=function(s)
  underride(s,spr0)
  s.en=false
  s.s=2
  s.m=missile:new()
 end,
 --[[
 new=function(s)
  s.en=false
  s.s=2
  return override(spr0:new(),s)
 end,
 ]]
 upd=function(s)
  if s.y<119 then -- rollout complete
   s.y,s.vy = 119,0
  end
  if s.en then
   if btn(0) then s.x=max(5,s.x-2)   end
   if btn(1) then s.x=min(122,s.x+2) end
   if btn(4) then
    if s.b4==0 then
     s.b4=1
     s.m:shot()
    end
   else s.b4=0 end
  end
  s.m:upd()
  if s.s==1 then --miss
   --s.vy+=0.1
   s.sp=10
   s.mo=flr(tcnt(s)/5) --s.c%5
   if tcnt(s)==15 then
    s.s=2 -- out of screen
   end
  end
  spr0.upd(s)
 end,
 drw=function(s)
  s.m:drw()
  if s.s<2 then
   spr0.drw(s)
  end
 end,
 rout=function(s)
  if rest>0 and s.s==2 then
   rest-=1
   s.x,s.y=63,136
   s.vy=-4
   s.sp=7
   s.mo=0
   s.s=0
  end
  s.en=true
 end,
 miss=function(s)
  tini(s)
  s.s=1 -- miss
  s.vy=0.1
  s.en=false -- disable
  sfx(sfx_.miss,1) --shot
 end,
 idle=function(s)
  return s.s!=1 and s.m.st==nil
 end,
}

missile = {
 sp=8,
 vx=0, vy=-4,
 new=function(s)
  return override(spr0:new(),s)
 end,
 upd=function(s)
  if s.st then
   spr0.upd(s)
   if s.y<-5 then
    s.st=nil
    _cmb=1
   end
  elseif ship.en then
   s.x,s.y = ship.x,ship.y-6
  else
   s.y=200
  end
 end,
 shot=function(s)
  if s.st==nil then
   s.st = 1
   sfx(sfx_.shot,1) --shot
  end
 end,
}

bullet={
 sp=9,
 new=function(s,x,y,vx,vy)
  local o=override(spr0:new(),s)
  o.x,o.y,o.vx,o.vy=x,y,vx,vy
  return o
 end,
-- drw=function(s)
--  spr0.drw(s)
--  line(s.x,s.y,s.x+s.vx*100,s.y+s.vy*100)
--  print(""..s.vx,s.x+5,s.y-5)
--  print(""..s.vy,s.x+5,s.y+1)
-- end,
}
convoy={
 dc=0,  -- dance counter
 ci=40, -- charge interval init (stage matter)
 ini=function(s)
  s.x,s.vx = 0,-1
  s.ci = 0
  s.ar={}
  s.br={}
  tini(s)
  s.en=false
  s.go=true
 end,
 upd=function(s)
  s.ci+=1
  s.dc = (s.dc+0.1)%4
  if stage.ci!=nil then stage.ci=max(15,stage.ci-0.02) end
  local i,a
  if tcnt(s)%4==0 and s.go then s.x+=s.vx end
  s.al=0 --alives
  s.ac=0 --charges
  for i,a in pairs(s.ar) do
   a.px = ((i-1) % 6)*16+18 + s.x
   a.py = flr((i-1)/6)*14+10
   if a.md>0 then
    s.al+=1
    if a.px<6   then s.vx=1 end
    if a.px>120 then s.vx=-1 end
    --if s.ci>=stage[_stn].ci then
    if s.ci>=stage.ci then
     if s:noceil(a) and rnd(30)<1 and s.en then
      a:tochg()
      s.ci=0 
     end
    end
    a:upd()
    if a.md==2 then s.ac+=1 end -- in convoy
   end
  end
  if s.ac==s.al then sfx(-1,0) end
  for b in all(s.br) do
   b:upd()
   if b.y>130 then del(s.br,b) end
  end
  if 0<s.al and s.al<4 and s.en then
   s.lp=true  -- loop charging
   stage.ci=2 -- rapid
  else
   s.lp=false
  end
 end,
 noceil=function(s,a)
  --local c=s.ar[a.n+1-6].md
  return a.n<6 or s.ar[a.n+1-6].md==4
   --<=0 or cthen -- dead:0, dummy:-1
   --return true
 end,
 drw=function(s)
  local i,a
  for i,a in pairs(s.ar) do
   if a.md>0 and a:fly()==false then
    a:draw()
   end
  end
  for i,a in pairs(s.ar) do
   if a.md>0 and a:fly() then
    a:draw()
   end
  end
  for b in all(s.br) do
   b:drw()
  end
 end,
 setup=function(s)
  local i,j
  local n=0
  s.ar={}
  --local _st=stage[_stn]
  for j=1,4 do
   local b=0x20
   for i=1,6 do
    --if #_st.fm>=j and band(b,_st.fm[j])==b then
    if #stage.fm>=j and band(b,stage.fm[j])==b then
     --s.ar[#s.ar+1] = _st.ty[j]:new(n)
     s.ar[#s.ar+1] = stage.ty[j]:new(n)
    else
     s.ar[#s.ar+1] = {md=-1}
    end
    b/=2
    n+=1
   end
  end
  s.x,s.vx = 0,-1
  tini(s)
  s.en=false
 end,
 shot=function(s,b)
  s.br[#s.br+1]=b
 end,
 idle=function(s)
  return s.al==s.ac and #s.br==0
 end,
}

an_0 = {
 x=0,  y=0,
 vx=0, vy=0,
 sp=1, mo=0, rt=0,
 bl=0, 
 ct=0,  -- multi counter
 cy=1.2,-- chg vy
 ax=0.1,-- x_accel
 mx=3,  -- max vx
 tx=8,  -- turn margin
 tv=2,  -- turn enable vx
 pt=1,  -- pts(convoy).
 ff=50, -- fire freq
 ft={15,22}, -- fire trig
 pl={0x8B},
 new = function(s,n)
  s.n=n
  s.md=1
  s.om=0
  return override(spr0:new(),s)
 end,
 upd=function(s)
  if s.om!=s.md then 
   tini(s) 
  end
  --s.ct = (s.om!=s.md) and 0 or s.ct+1
  local nm=s.md
  if s.md==1 then     -- 1:turn in
   s:_tin()
  elseif s.md==2 then -- 2:convoy
   s:_cvy()
  elseif s.md==3 then -- 3:turn out
   s:_tout()
  elseif s.md==4 then -- 4:charge
   s:_chg()
  elseif s.md==5 then -- 5:escape
   s:_esc()
  elseif s.md==6 then -- 7:drop
  elseif s.md==7 then -- 6:hit
   s:_hit()
  -- 0:dead
  -- -1:dummy
  end
  s._anim(s)
  spr0.upd(s)
  s.om=nm
 end,
 fly=function(s)
  return s.md!=2 and s.md!=6 and s.md!=0
 end,
 tochg = function(s)
  if s.md==2 then
   s.md=3
  end
 end,
 _tin = function(s)
  if s.om!=s.md then
   s.rt = 8
   s.vx = 0
   s.y,s.vy = -8,2
   s.lc = 0  -- loop counter
  end
  s.x = s.px
  if s.y >= s.py and s.py+10 > s.y then
   s.md=2
  elseif s.py-16 < s.y then
   s.rt-=1 --flr((s.py-s.y)/3)
  end
 end,
 _cvy = function(s)
  s.rt=-1
  s.x,s.y = s.px,s.py
  s.sp=1
  local dc=(flr(convoy.dc)+(s.n%6))%4
  if dc%2==1 then
   s.y-=1
   s.x+=(dc==1 and -1 or 1)
   s.sp=2
  end
 end,
 _tout=function(s)
  if s.md!=s.om then
   sfx(sfx_.charge,0)
   s.rt=0
  end
  local v=sgn(s.n%6-3)  -- L/R
  s.rt=((s.rt*2+v)/2+16) % 16  -- +-0.5 per frame range:0..15
  s.vx=-sin(s.rt/16)*2
  s.vy=-cos(s.rt/16)*2
  if s.rt==8 then
   s.rt=8
   s.md=4
  end
 end,
 _chg = function(s)
  if s.om!=s.md then --init
   s.vx,s.ax=0,abs(s.ax)*sgn(ship.x-s.x)
   s.vy,s.ay=s.cy,0
   s.rt=8
  end
  local dx=s.x-ship.x
  if sgn(dx)==sgn(s.ax) and abs(dx)>s.tx and abs(s.vx)>=s.tv then
    s.ax=-s.ax
  end
  s.vx = mid(-s.mx, s.ax+s.vx, s.mx)
  if s.y>128+8 then
   if not convoy.lp then
    s.md=1
   else
    s.y=-16
    s.x=mid(8,s.x,120)
    s.lc+=1
   end
  end
  s:_trig()
  s:_rotp(ship)
  if s.lc>=3 and s.y>80 then
   s.md=5   -- escape
  end
 end,
 _esc = function(s)
  s.ax=0
  s.vx*=0.7
  s.vy=max(-5,s.vy-0.4)
  if tcnt(s)%2==1 and s.rt%16!=0 then
   s.rt+=sgn(s.rt-8)
  end
  if s.y<-8 then
   _fg:str("lost",mid(s.x,0,107),6,3,20,1,0.5)
   --str "lost"
   s.md=0
  end
 end,
 _hit = function(s)
  local cnt = tcnt(s)
  if cnt==0 then sfx(sfx_.hit,1) end
  s.rt=-1
  s.sp=10
  s.vx,s.vy,s.ax,s.ay=0,0,0,0
  s.mo=flr(cnt/2)
  if cnt>=6 then s.md=0 end
 end,
 _rotp = function(s,o,d)
  if d==nil then d=0.25 end
  if tcnt(s)%5==4 then 
   local a=atan2(o.x-s.x, o.y-s.y)
   a=(1+d-a)%1
   a=(rup(a*16)+16)%16
   s.rt+=sgz(a-s.rt)
   if o==ship then s.rt=mid(5,s.rt,11) end
  end
 end,
 _trig=function(s)
  if cont(tcnt(s)%s.ff,s.ft) then
   s:_fire()
  end
 end,
 _fire=function(s)
  convoy:shot(bullet:new(s.x,s.y,0,3))
 end,
 draw = function(s)
  -- 0 0,-,-
  -- 1 1,-,-
  -- 2 2,-,-
  -- 3 3,-,-
  -- 4 4,-,-
  -- 5 3,v,-
  -- 6 2,v,-
  -- 7 1,v,-
  -- 8 0,v,-
  -- 9 1,v,h
  -- A 2,v,h
  -- B 3,v,h
  -- C 4,-,h
  -- D 3,-,h
  -- E 2,-,h
  -- F 1,-,h
  if s.rt>=0 then -- rot to sp
   local r=rup(s.rt) % 16
   s.sv = 5<=r and r<=11
   s.sh = 9<=r and r<=15
   if r>=8 then r=r-8 end
   if r>=5 then r=8-r end
   s.sp = 2+r
  end
  spr0.drw(s)
  if s.x<=-8 then spr(93,0,s.y-1) end
  if s.x>=135 then spr(93,120,s.y-1,1,1,true,false) end
 end,
 _anim = function(s)
  if mid(1,s.md,6)==s.md then
   if s.bl==0 then
    if rnd(100)<1 then s.bl=6 end
   else
    s.bl=(s.bl+4)%30
   end
   s.mo = flr(s.bl/10)
  end
 end,
}
an_1 = {
 pl={0xf4},
 new=function(s,i)
  return override(an_0:new(i),s)
 end,
 draw=function(s)
  --pal(15,4)
  an_0.draw(s)
  --pal()
 end,
 _fire=function(s)
  local a=step(angl(s,ship),1/24)
  if abs(a)<0.120 then
   local vx,vy=vect(a,3)
   convoy:shot(bullet:new(s.x,s.y,vx,vy))
  end
 end,
}
an_gf = {
 pl={0x8c},
 new=function(s,i)
  return override(an_1:new(i),s)
 end,
}
function step(v,s)
 if v>=0.5 then v=-(1-v) end
 v += sgn(v)*(s/2)
 return int(v/s)*s
end
function angl(s,d)
 return atan2(d.y-s.y,s.x-d.x)
end
function vect(a,l)
 return -sin(a)*l,cos(a)*l
end

bgp = {
 m=0, -- stars/grid/warp
 new=function(s,i)
  o=override({},s)
  o.i=i
  o.x,o.y = flr(rnd(128)),flr(rnd(128))
  o.vy=(rnd(3)+1)/2
  o.b=flr(rnd(16))
  o.gx,o.gy=(i%8)*16+8,flr(i/8)*16+8
  return o
 end,
 upd=function(s)
  s.b=(s.b+1)%15
  s.y+=s.vy
  if s.y>128 then
   s.y=0
   s.m=_bg.m
  end
 end,
 drw=function(s)
  if s.m==0 then
   if s.b<10 then
    pset(s.x,s.y,6)
   end
  end
  if s.m==1 then
   pset(s.gx,(s.gy+_bg.c)%128,3)
  end
 end,
}
_bg={
 ini=function(s)
  s.m=0
  s.p={}
  s.c=0
  s.d=0
  for i=1,64 do
   s.p[i]=bgp:new(i)
  end
 end,
 upd=function(s)
  if s.t==0 then
   for p in all(s.p) do
    p.m=s.m
   end
  elseif s.t==2 then
   if tcnt(s)>6 then
    s.t=0
   end
  end
  s.c=(s.c+1)%128
  s.d=0
  for p in all(s.p) do
   p:upd()
   if p.m!=s.m then s.d+=1 end
  end
 end,
 drw=function(s)
  if s.t==2 then
   for i=0,128*64 do
    if rnd(5)<3 then
     pset(i%128,flr(i/128)*2,6)
    end
   end
   return
  end
  for p in all(s.p) do
   p:drw()
  end
 end,
 set=function(s,m)
  s.m=m % 16
  s.c=0
  s.t=flr(m/16)--t:transition 0/nil:now 1:natural 2:noiz
  tini(s)
 end,
 idle=function(s)
  return s.d==0
 end,
}
_pts={
 ini=function(s)
  s.h,s.l=0,0
 end,
 add=function(s,v)
  s.l+=v
  s.h+=flr(s.l/10000)
 end,
 drw=function(s)
  local st=""..s.l.."0"
  if s.h>0 then st=""..s.h..st end
  print(st,24-(#st*4),0)
 end,
}
_fg={
 -- string {str,x,y,color,maxct,blink,vy,ct}
 ini=function(s)
  s.st={}
 end,
 str=function(s,st,x,y,cl,ct,op,vy)
  if x<0 then x=64-(#st*2) end --center
  if vy==nil then vy=0 end
  s.st[#s.st+1]={s=st,x=x,y=y,c=cl,t=ct,o=op,v=vy,n=0}
 end,
 upd=function(s)
  local i
  for i in all(s.st) do
   i.n+=1
   i.y+=i.v
   if i.t>0 and i.n>=i.t then
    del(s.st,i)
   end
  end
 end,
 drw=function(s)
  local i
  color(7)
  -- score
  _pts:drw()
  -- combos
  if _cmb>1 then
   spr(76,65,0)
   print(" ".._cmb,65,0)
  end
  -- rest
  if rest>=1 then
   for i=1,(rest) do
    spr(29,i*4-4,120)
   end
  end 
  ---str
  for i in all(s.st) do
   if i.o==nil or i.n!=4 then -- flicker
    if i.o==2 then -- combo
     spr(76,i.x,i.y)
    end
    print(i.s,i.x,i.y,i.c)
   end
  end
 end,
}

-- scenes
sc_title = {
 ini=function(s)
  --_nxt=nil
  _fcnt = 0      -- global frame count
  _fg:ini()
  _bg:ini()
  ship:ini()
  convoy:ini()
  ship.en=false
  convoy.en=false
  tini(s)
 end,
 upd=function(s)
  if btn(1) and tcnt(s)>30 then
   _pts:ini()
   _cmb=1
   --_stn=1
   stage:ini(1)
   score=0
   rest=3
   --ship:rout()
   _nxt=sc_call --:ini()
  end
 end,
 drw=function(s)
  map(1,0,23,40,10,1)
  print("rev.0.01r", 71,50)
  spr(13,63,70)
  spr(14,64-8,70-2,2,2)
  print("hit button to start",25,90)
 end,
}
sc_call={
 ini=function(s)
  tini(s)
 end,
 upd=function(s)
  if not _bg:idle() then
   tini(s)
   return
  end
  local cnt=tcnt(s)
  if cnt==15 then
   if convoy.al==0 then
    convoy:setup()
   end
  elseif cnt==30 then
   _fg:str("stage "..stage.num, -1,70,7,60)
  elseif cnt==45 then
   ship:rout()
   convoy.en=true
   _nxt=sc_round --:ini()
  end
 end,
 drw=function(s)
  print(" as ".._bg.d,64,32)
 end,
}
sc_round={
 ini=function(s)
  --convoy:setup()
  --ship.en=false
 end,
 upd=function(s)
  --[[
  if ship.en==false and 
     convoy.en==false and 
     ]]
  if
     ship:idle() and 
     convoy:idle() then
   if convoy.al==0 then
    _nxt=sc_clear --:ini()
   elseif ship.s>0 then --ship.en==false then
    if rest>0 then
     _nxt=sc_call --:ini()
    else
     _nxt=sc_over --:ini()
    end
   end
  end
  local m=false -- missed
  for a in all(convoy.ar) do
   _gpx=-5
   if a.md>0 then
    -- missile vs enemy
    if ship.m.st and ship.m:hit(a) then
     if false==convoy.go then
     end
     local p=a.pt
     if a:fly() then 
      p*=2*_cmb
      if _cmb>1 then
       _fg:str(" ".._cmb,a.x-8,a.y-8,7,20,2,-0.5)
      end
     end
     if _cmb<10 and not a:fly() then _cmb+=1 end
     _pts:add(p)
     a.md=7
     ship.m.st=nil
    elseif not a:fly() then
     if _gpx>=-2 then
      convoy.go=false
     end
    end
    -- ship vs enemy
    if ship:hit(a) then m=true end
   end
   if not ship.m.st then
    convoy.go=true
   end
  end
  -- bullets vs ship
  for b in all(convoy.br) do
   if ship:hit(b) then m=true end
  end
  if m then
   ship:miss()
   _cmb=1
   convoy.en=false
   --[[
   if rest==1 then 
    _nxt=sc_over --:ini() 
   end
   ]]
  end
 end,
 drw=function(s)
 end,
}
sc_clear = {
 ini=function(s)
  tini(s)
  ship.en=false
  _fg:str("t.b.d", -1,70,7,30)
 end,
 upd=function(s)
  if tcnt(s)==30 then
   -- if not laststage
   --_stn += 1
   stage:ini()
   _nxt=sc_call --:ini()
  end
 end,
 drw=function(s)
  sc_round.drw(s)
 end,
}
sc_over = {
 ini=function(s)
  tini(s)
  -- bgm
 end,
 upd=function(s)
  if tcnt(s)==30 then
   _fg:str("game over", -1,70,7,-1)
  elseif tcnt(s)>30 and btn(1) then
   _nxt=sc_title --:ini()
  end
 end,
 drw=function(s)
  sc_round.drw(s)
 end,
}

stage = {
 ini=function(s,n)
  s.max = #s.t
  s.num = n==nil and s.num+1 or n
  override(s,s.t[s.num])
  _bg:set(s.bg)
 end,
 t={{
 fm = {0x3f,0x2a,0x3f}, --,0x15},
 ty = {an_1,an_gf,an_0,an_0},
 st = {an_0,an_0}, -- stocks
 bg = 0x21,
 ci = 50,  -- charge interval
-- si = 20,  -- shot interval
 }, {
 fm = {0x3f,0x21,0x1e}, --,0x15},
 ty = {an_0,an_1,an_0,an_gf},
 st = {an_0,an_0}, -- stocks
 bg = 0x20,
 ci = 30,  -- charge interval
-- si = 20,  -- shot interval
 }},
}

function _init()
 --_nxt=nil
 _pts:ini()
 _cmb=1
 scn=sc_title
 sc_title:ini()
 --_fg:ini()
 --_bg:ini()
 --ship:ini()
 --convoy:ini()
 score=0
 rest=3
 dlog("----","log.txt")
end

function _update()
 _fcnt += 1
 _bg:upd()
 if _nxt!=nil then
  _nxt:ini()
  scn=_nxt
  _nxt=nil
 end
 assert(scn!=nil)
 scn:upd()
 convoy:upd()
 ship:upd()
 _fg:upd()
end

function _draw()
 cls(0)
 _bg:drw()
 scn:drw()
 convoy:drw()
 ship:drw()
 _fg:drw()
 
 -- debug
 if(stage.ci!=nil) print("ci:"..stage.ci,0,100)
end



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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008088808000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000808080000000000
00000000444444000000000044444400000000004444440000000000000000000000000000000000000000000000000070700000000000000080800000000000
00000044444444400000004444444440000000444444444000000804444440000000080444444000000008044444400007000000000000000008000000000000
00080444fef4444400080444fef4444400080444e5f4444400004444444444400000444444444440000044444444444070700000aaa000000000000000000000
0044400ff55444440044400ff5f444440044400ff5f44444000008000fef4444000008000fef4444000008000e5f444400000000aaa000000000000000000000
0008000ffff444440008000ffff444440008000ffff4444400000000ff55444400000000ff5f444400000000ff5f444400000000a00000000000000000000000
00000000ffff444400000000ffff444400000000ffff444400000000ffff444400000000ffff444400000000ffff444400000000a00000000000000000000000
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
000000000000000000000000000000000000b0330000000000000b033000000000000b03300000000033333b0b30000088008800880008808888888080088008
00000000000000000000000000000000000003333000000000000033330000000000003333000000000000333003300088008800888008808800000000880088
00000000000000000000000000000000300b33333000000003000b333300000000030b0333000000000000000333b00008008000888808808800000008800880
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
dfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdfdf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e2cee2e2e2e2e2e2e2e2e2e2e2e2e2e2e0e0e0e0e0e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cdb1b0e2e2e2e2e200b0b100b0b0e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e2cfe2e2e2e2e2e200000000000000e200808182830000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e2dce2e2e2e2e2e200000000000000e200909192930000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b0e2e2e2e2e2e2e2e2e2e2e2e2e20000a0a1a2a30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000b0b1000000e2e2e2e2e200b0b10000b0b1b2b30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000c4703b4703947035470314702e4602946025460214501e4401b4401744013430104300d4300b42008420074200541003410034100241002410014100141001410014100141001510015700000000000
00090c0e35311303112c321283212532122311203111e3111c3111a31119311183111a312153110c3110831606370053701810018100181001810018100153001810018300153002140001400014000140000000
000100001777015570107700d5700c7700a5700a7700a5700f7701057016770175701d77022570287702b5702f770335703677038570397703757000000000000000000000000000000000000000000000000000
00020000376700b3703b6703b67010370153703c6703f670123703e6700f3703d6700a37036660093602966007360206600636021660033501c65001340146400153014630015200962001510056100260000000
00030014091100c1100e1100f110111101111011110101100f1100e1100b110091100611004110021100111001110011100211004110071100b1100c1100b1100a11009110071100411002110041100711009110
000c00002405325063240732607324073270732607328073260632806326053270532603328033270232802325013250132501326013260132600326003250032500323003230032300326003260032800329003
000b00002153223532215321f5321f5221f51224200242002420024200242000c2050e203102030c2030e200102000c200102001120013200060000d000150001f0001f0001f0001f0001f00021000210000b000
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

