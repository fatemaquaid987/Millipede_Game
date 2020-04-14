#Millipede Infraction Protection Simulator
#CS0447
#By Fatema Quaid
.data
# LED colors (don't change)
.eqv	LED_OFF		0
.eqv	LED_RED		1
.eqv	LED_ORANGE	2
.eqv	LED_YELLOW	3
.eqv	LED_GREEN	4
.eqv	LED_BLUE	5
.eqv	LED_MAGENTA	6
.eqv	LED_WHITE	7

# Board size (don't change)
.eqv	LED_SIZE	2
.eqv	LED_WIDTH	32
.eqv	LED_HEIGHT	32

# System Calls
.eqv	SYS_PRINT_INTEGER	1
.eqv	SYS_PRINT_STRING	4
.eqv	SYS_PRINT_CHARACTER	11
.eqv	SYS_SYSTEM_TIME		30

# Key states
leftPressed:		.word	0
rightPressed:		.word	0
upPressed:		.word	0
downPressed:		.word	0
actionPressed:		.word	0

#player coordinates
player_x:  .word 0
player_y:  .word 31
isMove: .word 0
life : .word 3

#Projectile coordinates
pro_x: .word -1
pro_y: .word -1
isProjectile: .word 0

# Frame counting
lastTime:	.word	0
frameCounter:	.word	0
seconds: .word 0

#millipede 
coordinateX: .word -9, -8, -7, -6, -5, -4, -3, -2, -1, 0
coordinateY : .word -1,-1,-1,-1,-1,-1,-1,-1,-1,0
offx: .word 0
offy : .word 0
counter_right: .word 1,1,1,1,1,1,1,1,1,1
mil_length: .word 10

#millipede dropping
isdropping: .word 0
drop_x: .word 32
drop_y: .word 32

#win/loose
win : .word 0
loose: .word 0
winprompt: .asciiz "congratulations! You win!\n"
looseprompt: .asciiz "Sorry! you loose!\n"

.text
.globl main
main:	
	# Initialize the game state
	jal	initialize				# initialize()
	
	# Run our game!
	jal	gameLoop				# gameLoop()
	
	# The game is over.

	# Exit
	li	v0, 10
	syscall						# syscall(EXIT)

# void initialize()
#   Initializes the game state.
initialize:
	push	ra
	
	# Clear the screen
	li	a0, 1
	jal	displayRedraw				# displayRedraw(1);
	
	# Initialize anything else
	
	pop	ra
	jr	ra
				
# void gameLoop()
#   Infinite loop for the game logic
gameLoop:
	push  ra
	push  s0
	push s1
	li t2, 40
#loop to put 40 random mushrooms at the beginning of game
put40:
	beq t2, 0, start                              #while(t0 != 0) addObstacle()
	li a0, 0 #x-lower bound
	li a1, 1 #y-lowerbound
	li a2, 31 #x-upper bound
	li a3, 30 #y-upperbound
	jal addObstacle
	add t2, t2, -1                                  #t0--
	j put40
#start gameloop
start:
	li	a0, 0
	jal	displayRedraw				# displayRedraw(0);
	jal	getSystemTime
	sw v0, lastTime                                 #lastTime = getSystemTime()

gameLoopStart:						# loop {
	jal	getSystemTime				# 	v0 = getSystemTime();
	lw s0, lastTime                              #       s0 = LastTime
	# Determine if a frame passed
	sub s0, v0, s0 
	move a0, v0
	jal	handleInput				# 	v0 = handleInput(elapsed: a0);
	
	blt s0, 100, gameLoopStart			# 	if (s0 - lastTime >= 100) {
	move s0, a0
	# Update last time
	sw	s0, lastTime				# 		lastTime = s0;
	
	
	# Update our game state (if a frame elapsed)
	move	a0, s0
	jal	update					# 		v0 = update();
	
	# Exit the game when it tells us to
	beq	v0, 1, gameLoopExit			# 		if (v0 == 1) { break; }
	
	# Redraw (a0 = 0; do not clear the screen!)
	li	a0, 0
	jal	displayRedraw				# 		displayRedraw(0);
							#	}
	j	gameLoopStart				# }

#exit game
gameLoopExit:
	pop s1
	pop s0
	pop ra
	jr ra					# return;
	

#void addObstacle()					
addObstacle:
	push ra
	push s0
	push s1
	
	move s0, a0
	move s1, a1
	
	move a1, a2                        # x = getRandomnumber(0,31)
	li v0, 42
	syscall
	
	move t0, a0
	
	move a1, a3                       # y = getRandomnumber(1,31)
	li v0, 42
	syscall
	
	move t1, a0
	
	add a0, t0, s0
	add a1, t1, s1
	jal displayGetLED
	bne v0, 0, obstacleExit            #if(displayGetLED(x,y) == OFF)
	li a2, LED_GREEN                   # {displaySetLED(x,y,GREEN)}
	jal displaySetLED
obstacleExit:
        li v0, 0
	pop s1
	pop s0
	pop ra
	jr ra	
# int getSystemTime()
#   Returns the number of milliseconds since system booted.
getSystemTime:
	# Now, get the current time
	li	v0, SYS_SYSTEM_TIME
	syscall						# a0 = syscall(GET_SYSTEM_TIME);
	
	move	v0, a0
	
	jr	ra					# return v0;
	
# bool update(elapsed)
#   Updates the game for this frame.
# returns: v0: 1 when the game should end.
update:
	push	ra
	push	s0
	push s1
	
	# Increment the frame counter
	lw t0, frameCounter
	add t0, t0, 1
	sw t0, frameCounter			# frameCounter++;
	
	#if ten frames have passes, drop the dropping
	li t1, 10
	div t0, t1
	mfhi t1
	bne t1, 0, continue_update
	li a0, 0
	li a1, 0
	li a2, 31
	li a3, 31
	jal addObstacle
	j drop
continue_update:
	li s0, 0				# s0 = 0;
	
	#update player
	lw a0, player_x
	lw a1, player_y
	li t0, 0
	sw t0, isMove                          #isplayer moving or not
	jal updatePlayer                        
	
	or s0, s0, v0			# s0 = s0 | updatePlayer(player_x, player_y);
	
	lw a0, pro_x
	lw a1, pro_y
	jal moveProjectile
	or s0, s0, v0			# s0 = s0 | moveProjectile(pro-x, pro-y);
	
	la a0, coordinateX
	la a1, coordinateY
	la a2, counter_right                    #counter_right(i) =1 means degment i goes right
	
	# Update all of the game state
	jal updateStuff
	or s0, s0, v0				# s0 = s0 | updateStuff(millipedex, millepedey, counter_right);
	
	lw a0, drop_x
	lw a1, drop_y
	jal moveDropping
	or s0, s0, v0			# s0 = s0 | moveDropping(drop_x, drop_y);
	
	#check win/loose conditions
	lw t0, win
	beq t0, 1, win_exit     #if win ==1
	lw t0, loose
	beq t0, 1, loose_exit  #if loose ==1
winloose:
	or s0, s0, v0
	j _updateExit
loose_exit:
	li v0, 4
	la a0, looseprompt       #printString(looseprompt)
	syscall
	li v0, 1
	j winloose
	
win_exit:
	li v0, 4
	la a0, winprompt       #printString(looseprompt)
	syscall
	li v0, 1
	j winloose
_updateExit:
	move	v0, s0
	pop     s1
	pop	s0
	pop	ra
	jr	ra					# return s0;

drop:
	lw t0, isdropping
	beq t0, 1, continue_update
	li a0, 0
	li a1, 31
	li v0, 42
	syscall
	move t0, a0
	li a1, 0
	li a2, LED_WHITE
	jal displaySetLED
	sw a0, drop_x
	sw a1, drop_y
	li t0, 1                   #isdropping = true
	sw t0, isdropping
	j continue_update

#int move dropping(drop_x, drop_y)
moveDropping:
	push ra
	bgt a1 ,31, droppingOut #if dropping is out of screen, dont display
	li a2, LED_OFF
	jal displaySetLED      #turn off current LED
	beq a1, 31, droppingOut
	add a1, a1, 1
	jal displayGetLED     # v0 = LED color
	beq v0, 5, decreaseLife
	beq v0, 1, dropping_skip #dropping can go past mushroom and millipede
	beq v0, 4, dropping_skip
	li a2, LED_WHITE
	jal displaySetLED
	sw a1, drop_y
	j droppingExit
dropping_skip:                     #skip mushroom and millepede pixels if dropping hits one
	add a1, a1, 2
	li a2, LED_WHITE
	jal displaySetLED
	sw a1, drop_y
	j droppingExit
decreaseLife:                         #decrease players lives up to 3 times. if life ==0, player looses
	lw t0, life
	add t0, t0, -1
	sw t0, life
	beq t0, 0, loose_d
	li a2, LED_BLUE
	jal displaySetLED
	sw a1, drop_y
	j droppingExit
loose_d:
	li t0, 1
	sw t0, loose
	j droppingExit
droppingOut:
	li t0, 0
	sw t0, isdropping #if dropping goes out of level boundaries, isDropping = 0
	j droppingExit
droppingExit:
	li v0, 0
	pop ra
	jr ra
	
#int updatePlayer(player_x, player_y)	
updatePlayer:
	push ra
	li a2, LED_BLUE
	jal displaySetLED  		#draw player at x, y
	
	#check if right button pressed
	lw t0, rightPressed
	beq t0, 0, updatePlayerLeft   #if not , check left button
	bge a0, 31, updatePlayerLeft #if rightmost screen location reached
	move t0, a0                   #t0 = current x
	add a0, a0, 1
	jal displayGetLED
	beq v0, 1, loose_player
	beq v0, 4, updatePlayerExit   #if there's a mushroom at the given position, dont move  
	lw t1, isMove
	beq t1, 1, updatePlayerExit        
	sw a0, player_x  		#player_x+=1
	li a2, LED_BLUE
	jal displaySetLED
	move a0, t0
	li a2, LED_OFF                  #turn off prior position
	jal displaySetLED 
	li t1, 1
	sw t1, isMove 
	j updatePlayerExit
	
#check if left button pressed
updatePlayerLeft:
	lw t0, leftPressed
	beq t0, 0, updatePlayerUp  #if not check up button
	ble a0, 0, updatePlayerUp   #if leftmost screen location reached
	move t0, a0                 #t0 = current x
	add a0, a0, -1 
	jal displayGetLED 
	beq v0, 1, loose_player
	beq v0, 4, updatePlayerExit   #if there's a mushroom at the given position, dont move
	lw t1, isMove
	beq t1, 1, updatePlayerExit
	sw a0, player_x             #player_x-=1
	li a2, LED_BLUE
	jal displaySetLED
	move a0, t0
	li a2, LED_OFF             #turn off prior position
	jal displaySetLED
	li t1, 1
	sw t1, isMove
	j updatePlayerExit
	
#check if up button pressed
updatePlayerUp:
	lw t0, upPressed
	beq t0, 0, updatePlayerDown #if not check down button
	ble a1, 0, updatePlayerDown #if top of screen reached
	move t0, a1                 #t0 = current y
	add a1, a1, -1 
	jal displayGetLED 
	beq v0, 1, loose_player
	beq v0, 4, updatePlayerExit   #if there's a mushroom at the given position, dont move
	lw t1, isMove
	beq t1, 1, updatePlayerExit
	sw a1, player_y               #player_y-=1
	li a2, LED_BLUE
	jal displaySetLED 
	move a1, t0 
	li a2, LED_OFF              #turn off prior position
	jal displaySetLED
	li t1, 1
	sw t1, isMove
	j updatePlayerExit

#check if  down button pressed
updatePlayerDown:
	lw t0, downPressed
	beq t0, 0, updateProjectile   #if not check B key
	bge a1, 31, updateProjectile  #if bottom of screen  reached
	move t0, a1                 #t0 = current y
	add a1, a1, 1 
	jal displayGetLED  
	beq v0, 1, loose_player
	beq v0, 4, updatePlayerExit    #if there's a mushroom at the given position, dont move
	lw t1, isMove
	beq t1, 1, updatePlayerExit
	sw a1, player_y           #player_y+=1
	li a2, LED_BLUE
	jal displaySetLED
	move a1, t0
	li a2, LED_OFF          #turn off current position
	jal displaySetLED
	li t1, 1
	sw t1, isMove
	j updatePlayerExit

#check if B key pressed to fire projectile
updateProjectile:
	lw t0, actionPressed
	beq t0, 0, updatePlayerExit #if not exit
	lw t1, isProjectile
	beq t1, 1, updatePlayerExit #if Projectile not on screen, fire, else exit
	#add a1, a1, -1             #projectile y-=1
	lw a0, player_x
	li a2, LED_YELLOW          #display projectile
	jal displaySetLED
	sw a0, pro_x
	sw a1, pro_y
	li t0, 1                   #isProjectile = true
	sw t0, isProjectile

updatePlayerExit:
	li v0, 0       #return 0 
	pop ra
	jr ra

#if player hits centipede, player looses
loose_player:
	li t0, 1                 #return 1
	sw t0, loose
	j updatePlayerExit
	

	

#int moveProjectile(player_x, player_y -1)
#a0 = player_x
#a1 = player y -1
moveProjectile:
	push ra
	blt a1 ,0, ProjectileOut #if projectile is out of screen, dont display
	li a2, LED_OFF
	jal displaySetLED
	beq a1, 0, ProjectileOut
	add a1, a1, -1
	jal displayGetLED     # v0 = LED color
	beq v0, 1, milli_Destroy
	beq v0, 4, ProjectileDestroy  #if projectile hits mushroom, destroy it
	li a2, LED_YELLOW
	jal displaySetLED
	sw a1, pro_y
	

ProjectileExit:
	li v0, 0
	pop ra
	jr ra

ProjectileOut:      #pojectile is out of screen 
	li t0, -1
	sw t0, pro_x
	li t0, -1
	sw t0, pro_y
	li t0, 0
	sw t0, isProjectile #if projectile goes out of level boundaries, isprojectile = 0
	j ProjectileExit

ProjectileDestroy:
	li a2, LED_OFF          #turn the LED off(destroy mushroom and projectile)
	jal displaySetLED
	li t0, -1
	sw t0, pro_x           #projectile x =0
	sw t0, pro_y           #projectile y =0
	li t0, 0
	sw t0, isProjectile
	j ProjectileExit

milli_Destroy:
	li t0, 0
	sw t0, isProjectile    #projectile not on screen, isprojectile =0
	li t0, -1               #reset projectile 
	sw t0, pro_x           #projectile x =0
	sw t0, pro_y           #projectile y =0
	lw t0, mil_length      #update mili length
	add t0,t0, -1
	sw t0, mil_length     #mil_length --
	ble t0, 0, win_p
	j ProjectileExit
win_p:
	li t0, 1
	sw t0, win
	j ProjectileExit
# int updateStuff(centipede x[], centipede_y[], counter_right[])
updateStuff:
	push ra
	push s0
	push s1
	push s2
	push s3
	push s4
	
	move s0, a0
	move s3, a1
	move s4, a2
	
	li s2, 0          #turn off prior leds 
	lw a0, offx      
	lw a1, offy
	li a2, LED_OFF
	jal displaySetLED
	
updateStuffLoop:
	lw t0, mil_length
	ble t0, 0, win_m               #if(mil_length <1 , player wins)
	beq s2, t0, _updateStuffExit #if all segments of millepede are displayed, exit
	lw a0, (s0)
	lw a1, (s3)
	beq a0, 32, go_left          #if x == 32, go left
	beq a0, -1, go_right         #if y ==-1, go right
	blt a0, -1, dontDraw
	jal displayGetLED
	beq v0,5, loose_m        #if player is at the position, loose
	beq v0, 4, go_left_obstacle  #if mushroom is at the position, go_left_obstacle
	lw a0, (s0)
	lw t4, (s4)
	add s1, a0, t4               #x+= t4
	sw s1, (s0)
update_prior: 
	beq s2, 0, change            #if current segment is the last segment of millepede, prior led has to be turned off
continue:
	jal displayGetLED
	beq v0, 4, goPastMushroom
	li a2, LED_RED          
	jal displaySetLED
	
#continue to draw other segments
continue_right:
	add s0, s0, 4
	add s3, s3, 4
	add s4,s4, 4
	add s2,s2,1
	j updateStuffLoop
dontDraw:
	add s1, a0, t4               #x+= t4
	sw s1, (s0)
	#beq s2, 9, change            #if current segment is the last segment of millepede, prior led has to be turned off
	j continue_right
goPastMushroom:
	li a2, LED_GREEN          
	jal displaySetLED
	j continue_right

#reset millipede to upper left corner 
reset:  
	lw t0, (s0)
	add t0, t0, -1
	sw t0, (s0)
	li t0, 0
	sw t0, (s3)
	li t4, 1
	sw t4, (s4)
	j update_prior
	

go_left_obstacle:
	lw t4, (s4)
	#if mushroom encountered while going right, go left
	beq t4, 1, go_left
	#else go right
	j go_right
#go left if hit right wall
go_left:
	
	add a0, a0 , -2 #store the next position of that segment
	sw a0, (s0) 
	add a0, a0 , 1 
	beq a1, 31, reset #if corner of screen, reset millepede
	add a1, a1, 1
	sw  a1, (s3)
	li t4, -1
	sw t4, (s4)
	ble a0, -1, continue_right
	j update_prior
#go right if hit left wall
go_right:
	add a0, a0 , 2
	sw a0, (s0)  
	add a0, a0 , -1
	beq a1, 31, reset  #if corner of screen, reset millepede
	add a1, a1, 1
	sw  a1, (s3)
	li t4, 1
	sw t4, (s4)
	j update_prior

# stores coordinates which have to be turned off in next frame	
 change:
 	jal displayGetLED
	beq v0, 4, continue
 	sw a0, offx
 	sw a1, offy
 	j continue
 
#if millepede is completely destroyed, player wins
win_m:
	
	li t0, 1           #return 1
	sw t0, win
	j _updateStuffExit
	
# if player hits centipede, player looses
loose_m:
	li t0, 1
	sw t0, loose
	j _updateStuffExit
	
_updateStuffExit:

	# Return 0 so the game loop doesn't exit
	li	v0, 0
	pop s4
	pop s3
	pop s2
	pop s1
	pop s0
	pop	ra
	jr	ra					# return 0;


# LED Input Handling Function
# -----------------------------------------------------
	
# bool handleInput(elapsed)
#   Handles any button input.
# returns: v0: 1 when the game should end.
handleInput:
	push	ra
	
	# Get the key state memory
	li	t0, 0xffff0004
	lw	t1, (t0)
	
	# Check for key states
	and	t2, t1, 0x1
	sw	t2, upPressed
	
	srl	t1, t1, 1
	and	t2, t1, 0x1
	sw	t2, downPressed
	
	srl	t1, t1, 1
	and	t2, t1, 0x1
	sw	t2, leftPressed
	
	srl	t1, t1, 1
	and	t2, t1, 0x1
	sw	t2, rightPressed
	
	srl	t1, t1, 1
	and	t2, t1, 0x1
	sw	t2, actionPressed
	
	move	v0, t2
	
	pop	ra
	jr	ra
	
# LED Display Functions
# -----------------------------------------------------
	
# void displayRedraw()
#   Tells the LED screen to refresh.
#
# arguments: $a0: when non-zero, clear the screen
# trashes:   $t0-$t1
# returns:   none
displayRedraw:
	li	t0, 0xffff0000
	sw	a0, (t0)
	jr	ra

# void displaySetLED(int x, int y, int color)
#   sets the LED at (x,y) to color
#   color: 0=off, 1=red, 2=yellow, 3=green
#
# arguments: $a0 is x, $a1 is y, $a2 is color
# returns:   none
#
displaySetLED:
	push	s0
	push	s1
	push	s2
	
	# I am trying not to use t registers to avoid
	#   the common mistakes students make by mistaking them
	#   as saved.
	
	#   :)

	# Byte offset into display = y * 16 bytes + (x / 4)
	sll	s0, a1, 6      # y * 64 bytes
	
	# Take LED size into account
	mul	s0, s0, LED_SIZE
	mul	s1, a0, LED_SIZE
		
	# Add the requested X to the position
	add	s0, s0, s1
	
	li	s1, 0xffff0008 # base address of LED display
	add	s0, s1, s0    # address of byte with the LED
	
	# s0 is the memory address of the first pixel
	# s1 is the memory address of the last pixel in a row
	# s2 is the current Y position	
	
	li	s2, 0	
_displaySetLEDYLoop:
	# Get last address
	add	s1, s0, LED_SIZE
	
_displaySetLEDXLoop:
	# Set the pixel at this position
	sb	a2, (s0)
	
	# Go to next pixel
	add	s0, s0, 1
	
	beq	s0, s1, _displaySetLEDXLoopExit
	j	_displaySetLEDXLoop
	
_displaySetLEDXLoopExit:
	# Reset to the beginning of this block
	sub	s0, s0, LED_SIZE
	
	# Move to next row
	add	s0, s0, 64
	
	add	s2, s2, 1
	beq	s2, LED_SIZE, _displaySetLEDYLoopExit
	
	j _displaySetLEDYLoop
	
_displaySetLEDYLoopExit:
	
	pop	s2
	pop	s1
	pop	s0
	jr	ra
	
# int displayGetLED(int x, int y)
#   returns the color value of the LED at position (x,y)
#
#  arguments: $a0 holds x, $a1 holds y
#  returns:   $v0 holds the color value of the LED (0 through 7)
#
displayGetLED:
	push	s0
	push	s1

	# Byte offset into display = y * 16 bytes + (x / 4)
	sll	s0, a1, 6      # y * 64 bytes
	
	# Take LED size into account
	mul	s0, s0, LED_SIZE
	mul	s1, a0, LED_SIZE
		
	# Add the requested X to the position
	add	s0, s0, s1
	
	li	s1, 0xffff0008 # base address of LED display
	add	s0, s1, s0    # address of byte with the LED
	lbu	v0, (s0)
	
	pop	s1
	pop	s0
	jr	ra
