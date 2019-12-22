pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- main
-- music: "space"
--  from pico-8 tunes vol. 1
--  by @gruber_music / @krajzeg
function _init()
 init_game_state()
end
-->8
-- rhythm
local period=80
local gap=0.25

local function get_progress()
 local ticks=stat(26)
 return (ticks%period)/period
end

function test_rhythm()
 local p=get_progress()
 return p<gap or
        (1-gap)<p
end

function test_rhythm_2()
 local p=get_progress()
 return (1-gap*2)<p
end

function init_rhythm()
 music(18, 100)
end

function draw_rhythm()
 local p=get_progress()
 
 if test_rhythm() then
  rectfill(62,127,66,127-6)
 elseif test_rhythm_2() then
  rectfill(62,127,66,127-2)
 else
  rectfill(62,127,66,127-4)
 end
 
 for i=1,3 do  
  local dx=(p-i)*16
  local x=64-dx
  rectfill(x,127,x,127-2,7)  
  local x=65+dx
  rectfill(x,127,x,127-2,7)
 end
end
-->8
-- elevator and floors
local function has_space()
 return passengers[9]==0
end

local function add_p(floor)
 for i=1,9 do
  if passengers[i]==0 then
   passengers[i]=floor
   return
  end
 end
end

local function del_p(floor)
 for i=1,9 do
  if passengers[i]==floor then
   for j=i,8 do
    passengers[j]=passengers[j+1]
   end
   passengers[9]=0
   return true
  end
 end
 return false
end

function init_elevator()
 min_floor=1
 max_floor=9
 first_floor_pos={33+8*6,113-2*8}
 floor_size={-8,8}

 passengers={0,0,0,0,0,0,0,0,0} 
 current_floor=1
 overflow_floor=0
end

function update_elevator()
 local can_move=test_rhythm()
 
 local dp={0,0}
 if (btnp(➡️)) dp[1]-=1
 if (btnp(⬅️)) dp[1]+=1
 if (btnp(⬆️)) dp[2]+=1
 if (btnp(⬇️)) dp[2]-=1
 
 if dp[2]~=0 then
  success=can_move
  if success then
   current_floor+=dp[2]
   if current_floor<min_floor then
    current_floor=min_floor
    success=false
   elseif max_floor<current_floor then
    current_floor=max_floor
    success=false
   else
    sfx(1,3)
   end
  end
  if (not success) sfx(3,3)
 elseif dp[1]~=0 then
  success=can_move
  if success then
   if dp[1]<0 then
    success=has_space()
    if success then
     local d=dequeue(current_floor)
     success=d~=nil
     if success then
      add_p(d)
      sfx(4,3)
     end
    end
   else
    success=del_p(current_floor)
    if success then
     delivery_completed()
    end
   end
  end
  if (not success) sfx(3,3)
 end
end

function draw_elevator()
 local x=first_floor_pos[1]
 local y=-(current_floor-1)*floor_size[2]+first_floor_pos[2]
 spr(4,x-1,y-1)
 
 color(7)
 print('elevator',93,10)
 
 -- inside elevator
 color(7)
 local count=0
 for i=0,8 do
  local p=passengers[i+1]
  if p~=0 then
   local x=12*8+8*(i%3)+3
   local y=2*8+8*flr(i/3)+2
   print(p,x,y)
   count+=1
  end
 end

 -- elevator small preview
 for i=0,count-1 do
  local xx=x+(i%3)*2
  local yy=y+flr(i/3)*2
  rectfill(xx,yy,xx+1,yy+1,3)
 end
 
 -- floors labels
 local x=first_floor_pos[1]+8+2
 local y=first_floor_pos[2]
 for i=1,9 do
  local is_dest=false
  for j=1,#passengers do
   if (passengers[j]==i) is_dest=true
  end
  if i==overflow_floor then
   color(8)
  else
   color(is_dest and 7 or 5)
  end
  print(i,x,y)
  y-=8
 end
end

-->8
-- queues
local function get_destination(floor)
 local skip= (1<floor and floor<9) and 3 or 2
 local n=9-skip
 n=flr(rnd(n))+1
 if (floor-1<=n) n+=skip
 return n
end

function dequeue(floor)
 local q=queues[floor]
 local d=q[1]
 if d==0 then
  return nil
 else
  for i=1,4 do
   q[i]=q[i+1]
  end
  q[5]=0
  return d
 end
end

function init_queues()
 gen_delay=1
 next_gen=rnd(gen_delay)+1
 max_queue=5
 queues={
	 {0,0,0,0,0},
	 {0,0,0,0,0},
	 {0,0,0,0,0},
	 {0,0,0,0,0},
	 {0,0,0,0,0},
	 {0,0,0,0,0},
	 {0,0,0,0,0},
	 {0,0,0,0,0},
	 {0,0,0,0,0},
	}
end

function update_queues()
 next_gen-=1/60
 if next_gen<0 then
  next_gen+=rnd(gen_delay)+1
  local floor=min_floor+flr(rnd(max_floor-min_floor+1))
  if queues[floor][5]==0 then
   for i=1,5 do
    if queues[floor][i]==0 then
     queues[floor][i]=get_destination(floor)
     break
    end
   end
  else
   overflow_floor=floor
   init_game_over_state()
  end  
 end
end

function draw_queues()
 local c=has_space() and 7 or 5
 local w=has_space() and 8 or 14
 local x=first_floor_pos[1]+floor_size[1]
 for i=min_floor,max_floor do
  local y=first_floor_pos[2]-floor_size[2]*(i-1)
  for j=1,5 do
   color(j<4 and c or w)
   local d=queues[i][j]
   if d~=0 then
	   local dx=x+floor_size[1]*(j-1)
    print(d,dx,y) 
   end
  end
 end
end
-->8
-- score
function init_score()
 score=0
end

function draw_score(x,y)
 color(9)
 x=x or 1
 y=y or 1
 print('score: '..score,x,y)
end

function delivery_completed()
 score+=100
 sfx(2,3)
end
-->8
-- game state
function init_game_state()
 init_rhythm()
 init_map()
 init_elevator()
 init_queues()
 init_score()
 
 _update60=update_game_state
 _draw=draw_game_state
end

function update_game_state()
 update_elevator()
 update_map()
 update_queues()
end

function draw_game_state()
 cls()
 map(0,0,0,0,16,16)
 
 if success then
  color(11)
 else
  color(8)
 end
 draw_rhythm() 
 draw_elevator()
 draw_queues()
 draw_score()
end

-->8
-- game over state
function init_game_over_state()
 music(-1, 100) 
 _update60=update_game_over_state
 _draw=draw_game_over_state
end

function update_game_over_state()
 if btnp(❎) then
  init_game_state()
 end
end

function draw_game_over_state()
 draw_game_state()
 
 local x=37
 local y=54
 rectfill(x,y,x+54,y+22,4)
 color(7)
 print('game over',x+2,y+2)
 draw_score(x+2,y+9)
 color(0)
 print('❎ to restart',x+2,y+16)
end
-->8
-- map
function init_map()
 previous_p=0
end

function update_map()
 local p=get_progress()
 if p<previous_p then
  for y=0,15 do
		 for x=0,15 do
		  local s=mget(x,y)
		  if fget(s,0) then
		   s+=((s%2==0) and -1 or 1)
		   mset(x,y,s)
		  end
		 end
	 end
 end
 previous_p=p
end
__gfx__
000000007777777777777777777777777777777755575555555575557ccccccc57cccccc7ccccccc000000000000000000000000000000000000000000000000
000000007111111111111111ddddddd77111111755557555555755557ccccccc57cccccc7ccccccc000000000000000000000000000000000000000000000000
000000007111111111111111ddddddd77111111755557555555755557ccccccc57cccccc7ccccccc000000000000000000000000000000000000000000000000
000000007111111111111111ddddddd77111111755575555555575557ccccccc57cccccc7ccccccc000000000000000000000000000000000000000000000000
000000007111111111111111ddddddd77111111755575555555575557ccccccc57cccccc7ccccccc000000000000000000000000000000000000000000000000
000000007111111111111111ddddddd77111111755557555555755557ccccccc57cccccc7ccccccc000000000000000000000000000000000000000000000000
000000007111111111111111ddddddd77111111755557555555755557ccccccc57cccccc7ccccccc000000000000000000000000000000000000000000000000
000000007111111111111111ddddddd77777777755575555555575557ccccccc57cccccc7ccccccc000000000000000000000000000000000000000000000000
cccccccc71111111ddddddddddddddd700000000ccccccc7cccccccc0000000000000000777777777ccccccc0000000000000000000000000000000000000000
cccccccc71111111ddddddddddddddd700000000ccccccc7cccccccc0000000000000000cccccccccccccccc0000000000000000000000000000000000000000
cccccccc71111111ddddddddddddddd700000000ccccccc7cccccccc0000000000000000cccccccccccccccc0000000000000000000000000000000000000000
cccccccc71111111ddddddddddddddd700000000ccccccc7cccccccc0000000000000000cccccccccccccccc0000000000000000000000000000000000000000
cccccccc71111111ddddddddddddddd700000000ccccccc7cccccccc0000000000000000cccccccccccccccc0000000000000000000000000000000000000000
cccccccc71111111ddddddddddddddd700000000ccccccc7cccccccc0000000000000000cccccccccccccccc0000000000000000000000000000000000000000
cccccccc71111111ddddddddddddddd700000000ccccccc7cccccccc0000000000000000cccccccccccccccc0000000000000000000000000000000000000000
cccccccc71111111ddddddddddddddd700000000ccccccc7cccccccc0000000000000000cccccccccccccccc0000000000000000000000000000000000000000
333333337dddddddddddddddddddddd700000000dddddddd7ddddddd000000000000000011111111dddddddd0000000000000000000000000000000000000000
333333337dddddddddddddddddddddd700000000dddddddd7ddddddd000000000000000011111111dddddddd0000000000000000000000000000000000000000
333333337dddddddddddddddddddddd700000000dddddddd7ddddddd000000000000000011111111dddddddd0000000000000000000000000000000000000000
333333337dddddddddddddddddddddd700000000dddddddd7ddddddd000000000000000011111111dddddddd0000000000000000000000000000000000000000
333333337dddddddddddddddddddddd700000000dddddddd7ddddddd000000000000000011111111dddddddd0000000000000000000000000000000000000000
333333337dddddddddddddddddddddd700000000dddddddd7ddddddd000000000000000011111111dddddddd0000000000000000000000000000000000000000
333333337dddddddddddddddddddddd700000000dddddddd7ddddddd000000000000000011111111dddddddd0000000000000000000000000000000000000000
3333333377777777777777777777777700000000dddddddd7ddddddd000000000000000011111111dddddddd0000000000000000000000000000000000000000
cccccccccccccccc7777777773333333700000001111111171111111000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc3333333333333333000000001111111171111111000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc3333333333333333000000001111111171111111000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc3333333333333333000000001111111171111111000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc3333333333333333000000001111111171111111000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc3333333333333333000000001111111171111111000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccc3333333333333333000000001111111171111111000000000000000000000000000000000000000000000000000000000000000000000000
777777777ccccccc3333333333333333000000001111111171111111000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000010101010000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010100102020900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101030303030303030311129290900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101535292929292905071129290900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101016262a2a2a2a2a05081919191a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101535292929292905071010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101016262a2a2a2a2a05081010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101535292929292905071010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101016262a2a2a2a2a05081010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101535292929292905071010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101016262a2a2a2a2a05081010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101535292929292905071010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202032323232323232332020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000300000c1300e1211011112111131111411115111151150a1050e00016005021050710500000051050000003105031050010500000021051b005031051a0050510504105000000710505105037053c7001b705
000300000c7300f021130111311524600200000c000210000c000190001a00000000246003c70029500295000c0002e5002e5000c60024600225000000022500297002b70029000297002460035000295001d000
000f000021515265250000009100071001f700000000510505100041000000007100051001c0001d0000310003100021000000005100031000a1000a100000000110002100031000410005100000000a10000000
01010000197770c000197770c0001c7670c0001c7570c0001e7570c000217470c000217370c000237370c000237270c000257170c000287170c0000c0000c00022000225002200022500246000a7000a0001d005
00020000133151f3152b31537315137001300008700080001b7000a7000370003000246002d0000a7000a00008700087000a7000c0001670016000167001650027500140000c7000c000220002e000220000a500
011200000c033247151f5152271524615227151b5051b5151f5201f5201f5221f510225212252022522225150c0331b7151b5151b715246151b5151b5051b515275202752027522275151f5211f5201f5221f515
011200000c0330802508744080250872508044187151b7151b7000f0251174411025246150f0240c7440c0250c0330802508744080250872508044247152b715275020f0251174411025246150f0240c7440c025
011200002452024520245122451524615187151b7151f71527520275202751227515246151f7151b7151f715295202b5212b5122b5152461524715277152e715275002e715275022e715246152b7152771524715
011200002352023520235122351524615177151b7151f715275202752027512275152461523715277152e7152b5202c5212c5202c5202c5202c5222c5222c5222b5202b5202b5222b515225151f5151b51516515
011200000c0330802508744080250872508044177151b7151b7000f0251174411025246150f0240b7440b0250c0330802508744080250872524715277152e715080242e715080242e715246150f0240c7440c025
011600000042500415094250a4250042500415094250a42500425094253f2050a42508425094250a425074250c4250a42503425004150c4250a42503425004150c42500415186150042502425024250342504425
011600000c0330c4130f54510545186150c0330f545105450c0330f5450c41310545115450f545105450c0230c0330c4131554516545186150c03315545165450c0330c5450f4130f4130e5450e5450f54510545
0116000005425054150e4250f42505425054150e4250f425054250e4253f2050f4250d4250e4250f4250c4250a4250a42513425144150a4250a42513425144150a42509415086150741007410074120441101411
011600000c0330c4131454515545186150c03314545155450c033145450c413155451654514545155450c0230c0330c413195451a545186150c033195451a5451a520195201852017522175220c033186150c033
010b00200c03324510245102451024512245122751127510186151841516215184150c0031841516215134150c033114151321516415182151b4151d215224151861524415222151e4151d2151c4151b21518415
011400001051512515150151a5151051512515150151a5151051512515150151a5151051512515150151a5151051512515170151c5151051512515170151c5151051512515160151c5151051512515160151c515
011400000c0330253502525020450e6150252502045025250c0330253502525020450e6150252502045025250c0330252502045025350e6150204502535025250c0330253502525020450e615025250204502525
011400002c7252c0152c7152a0252a7152a0152a7152f0152c7252c0152c7152801525725250152a7252a0152072520715207151e7251e7151e7151e715217152072520715207151e7251e7151e7151e7151e715
011400000c0330653506525060450e6150652506045065250c0330653506525060450e6150652506045065250c0330952509045095350e6150904509535095250c0330953509525090450e615095250904509525
0114000020725200152071520015217252101521715210152c7252c0152c7152c0152a7252a0152a7152a015257252501525715250152672526015267153401532725310152d715280152672525015217151c015
010e000005145185111c725050250c12524515185150c04511045185151d515110250c0451d5151d0250c0450a0451a015190150a02505145190151a015050450c0451d0151c0150012502145187150414518715
010e000021745115152072521735186152072521735186052d7142b7142971426025240351151521035115151d0451c0051c0251d035186151c0251d035115151151530715247151871524716187160c70724717
010e000002145185111c72502125091452451518515090250e045185151d5150e025090451d5151d025090450a0451a015190150a02505045190151a015050450c0451d0151c0150012502145187150414518715
010e000029045000002802529035186152802529035000001a51515515115150e51518615000002603500000240450000023025240351861523025240350000015515185151c51521515186150c615280162d016
010e000002145185112072521025090452451518515090450e04521515265150e025090451d5151d01504045090451d01520015210250414520015210250404509045280152d0150702505145187150414518715
011a00000173401025117341102512734120250873408025127341202501734010251173411025087340802505734050250d7340d025147341402506734060250873408025127341202511734110250d7340d025
010d00200c0331b51119515195152071220712145151451518615317151d5151d515125050c03314515145150c0330150519515195150d517205161451514515186153171520515205150d5110c033145150c033
011a00000a7340a02511734110250d7340d02505734050250673406025147341402511734110250d7340d0250a7340a02511734110250d7340d02508734080250373403025127341202511734110250d7340d025
010d00200c0331b511295122951220712207122c5102c51018615315143151531514295150c03329515295150c0330150525515255150d517205162051520515186153171520515205150d5110c033145150c033
01180000021100211002110021120e1140e1100e1100e1120d1140d1100d1100d1120d1120940509110091120c1100c1100c1100c1120b1110b1100b1100b1120a1100a1100a1100a11209111091100911009112
01180000117201172011722117221d7201d7201d7221d7221c7211c7201c7201c7201c7221c72218720187221b7211b7201b7201b7201b7221b7221d7221d7221a7201a7201a7201a7201a7221a7221672016722
011800001972019720197221972218720187201872018720147201472015720157201f7211f7201d7201d7201c7201c7201c7221c7221a7201a7201a7221a7251a7201a7201a7221a72219721197201972219722
011800001a7201a7201a7221a7221c7201c7201c7221c7221e7201e7202172021720247212472023720237202272022720227202272022722227221f7201f7202272122720227202272221721217202172221722
0118000002114021100211002112091140911009110091120e1140e1100c1100c1120911209110081100811207110071100711007112061110611006110061120111101110011100111202111021100211002112
0118000020720207202072220722217202172021722217222b7212b72029720297202872128720267202672526720267202672026720267222672228721287202672026720267202672225721257202572225722
010e00000c0231951517516195150c0231751519516175150c0231951517516195150c0231751519516175150c023135151f0111f5110c0231751519516175150c0231e7111e7102a7100c023175151951617515
010e000000130070200c51000130070200a51000130070200c51000130070200a5200a5200a5120a5120a51200130070200c51000130070200a51000130070200c510001300b5200a5200a5200a5120a5120a512
010e00000c0231e5151c5161e5150c0231c5151e5161c5150c0231e5151c5161e5150c0231c5151e5161c5150c0230c51518011185110c0231c5151e5161c5150c0231e7111e7102a7100c023175151951617515
010e0000051300c02011010051300c0200f010051300c02011010051300c0200f0200f0200f0120f0120f012061300d02012010071300e02013010081300f0201503012020140101201015030120201401012010
010700000c5370f0370c5270f0270f537120370f527120271e537230371e527230272f537260372f52726027165371903716527190271c537190371c527210271c53621036245262102624536330362452633026
018800000074400730007320073200730007300073200732007300073200730007320073000732007320073200732007300073000730007320073000730007300073200732007300073000732007300073200732
01640020070140801107011060110701108011070110601100013080120701106511070110801707012060110c013080120701106011050110801008017005350053408010070110601100535080170701106011
018800000073000730007320073200730007300073200732007300073200730007320073000732007320073200732007300073000730007320073000730007300073200732007300073000732007300073200732
0164002006510075110851707512060110c0130801207011060110501108017070120801107011060110701108011075110651100523080120701108017005350053408012070110601100535080170701106511
011800001d5351f53516525275151d5351f53516525275151f5352053518525295151f5352053518525295151f5352053517525295151f5352053517525295151d5351f53516525275151d5351f5351652527515
010c00200c0330f13503130377140313533516337140c033306150c0330313003130031253e5153e5150c1430c043161340a1351b3130a1353a7143a7123a715306153e5150313003130031251b3130c0331b313
010c00200c0331413508130377140813533516337140c033306150c0330813008130081253e5153e5150c1330c0430f134031351b313031353a7143a7123a715306153e5150313003130031251b3130c0333e515
011800001f5452253527525295151f5452253527525295151f5452253527525295151f5452253527525295151f5452353527525295151f5452353527525295151f5452253527525295151f545225352752529515
010c002013035165351b0351d53513025165251b0251d52513015165151b0151d51513015165151b0151d51513015165151b0151d51513015165151b0151d51513015165151b0151d51513015165251b0351d545
011200000843508435122150043530615014351221502435034351221508435084353061512215054250341508435084350043501435306150243512215034351221512215084350843530615122151221524615
011200000c033242352323524235202351d2352a5111b1350c0331b1351d1351b135201351d135171350c0330c0332423523235202351d2351b235202352a5110c03326125271162c11523135201351d13512215
0112000001435014352a5110543530615064352a5110743508435115152a5110d43530615014352a511084150d4350d4352a5110543530615064352a5110743508435014352a5110143530615115152a52124615
011200000c033115152823529235282352923511515292350c0332823529216282252923511515115150c0330c033115151c1351d1351c1351d135115151d1350c03323135115152213523116221352013522135
0112000001435014352a5110543530615064352a5110743508435115152a5110d435306150143502435034350443513135141350743516135171350a435191351a1350d4351c1351d1351c1351d1352a5001e131
011200000c033115152823529235282352923511515292350c0332823529216282252923511515115150c0330c033192351a235246151c2351d2350c0331f235202350c033222352323522235232352a50030011
0114001800140005351c7341c725247342472505140055352173421725287342872504140045351f7341f725247342472502140025351d7341d72524734247250000000000000000000000000000000000000000
011400180c043287252b0152f72534015377253061528725290152d72530015377250c0432f7253001534725370153c725306152b7252d01532725370153b7250000000000000000000000000000000000000000
0114001809140095351f7341f7252473424725091400953518734187251f7341f72505140055351f7341f7252473424725051400553518734187251f7341f7250000000000000000000000000000000000000000
0114001802140025351f7341f725247342472504140045351f7341f725247342472505140055352b7242b715307243071507140075352b7242b71534724347150000000000000000000000000000000000000000
011400180c0433772534015307252f0152d725306152d7252f0153072534015377250c0433772534015307252f0152d725306152d7252f0153072534015377250000000000000000000000000000000000000000
011400180c0433c7253701534725300152f725306152f7253001534725370153c7250c0433c7253701534725300152f725306152f7253001534725370153c7250000000000000000000000000000000000000000
011400180c043287252b0152f725340153772530615287252901530725370153c7250c043287252901530725370153c72530615287252901530725370153c7250000000000000000000000000000000000000000
011400180c003287052b0052f705340053770530605287052900530705370053c7050c0032f7053000534705370053c705306052b7052d00532705370053b7050000000000000000000000000000000000000000
000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00014344
00 00014344
01 00014344
00 00014344
00 02034344
02 02034344
00 04424344
00 04424344
00 04054344
00 04054344
01 04054344
00 04054344
00 06074344
02 08094344
01 0a0b4344
00 0c0d4344
00 0a0e4344
02 0c0e4344
00 10424344
01 100f4344
00 100f4344
00 10114344
00 12114344
02 12134344
01 14154344
00 14154344
00 16154344
00 16154344
00 18174344
02 16174344
00 19424344
01 191a4344
00 191a4344
00 1b1a4344
00 191c4344
02 1b1c4344
01 1d1e4344
00 1d1f4344
00 1d1e4344
00 1d1f4344
00 21204344
02 1d224344
00 27424344
01 24234344
00 24234344
02 26254344
01 28294344
03 2a2b4344
01 2d304344
00 2e304344
00 2d304344
00 2e304344
00 2d2c4344
00 2d2c4344
02 2e2f4344
01 31324344
00 31324344
00 33344344
02 35364344
01 3738433f
00 3738433f
00 393b433f
00 393c433f
02 3a3d433f

