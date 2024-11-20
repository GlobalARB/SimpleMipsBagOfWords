.text
	
isletter:
    ori $t0, $a0, 0x20 #Convert upper to lower, lower unaffected
    addi $t1, $t0, -97 #t1 = t0 - 97, calculate difference from a
    sltiu $v0, $t1, 26   #Set on < Immediate Unsigned, if {$t1<26} $v0=1
    jr $ra  

#### Do not move this separator. 
	
lettersmatch:
    ori $t0, $a0, 0x20 #Convert upper to lower, lower unaffected
    ori $t1, $a1, 0x20 #Convert upper to lower, lower unaffected
    seq $v0, $t0, $t1  #Set on Equal
	jr $ra
	
#### Do not move this separator.
	
nextword:
    addi  $sp, $sp, -12     #allocate stack space 
    sw    $ra, 8($sp)  
    sw    $s0, 4($sp) 
    sw    $s1, 0($sp)

    move  $s0, $a0          # $s0 = current pointer

nextword_skip_letters:
    lb    $s1, 0($s0)       #Load byte from address in $s0 into $s1
    beq   $s1, $zero, nextword_no_next_word   #If end of string, return 0

    move  $a0, $s1          #Prep argument for isletter
    jal   isletter         
    bne   $v0, $zero, nextword_skip_letter_char  #If letter: skip

    #Not a letter
    j     nextword_skip_nonletters

nextword_skip_letter_char:
    addi  $s0, $s0, 1       #Increment pointer
    j     nextword_skip_letters

nextword_skip_nonletters:
    lb    $s1, 0($s0)       # Load byte from address in $s0 into $s1
    beq   $s1, $zero, nextword_no_next_word   #If end of string, return 0

    move  $a0, $s1          #Prepare argument for isletter
    jal   isletter          
    beq   $v0, $zero, nextword_skip_nonletter_char  #If not letter, skip

    #Found next word
    move  $v0, $s0          #Set ret val
    lw    $s1, 0($sp)       
    lw    $s0, 4($sp)       
    lw    $ra, 8($sp)       
    addi  $sp, $sp, 12     
    jr    $ra              

nextword_skip_nonletter_char:
    addi  $s0, $s0, 1       # Increment pointer
    j     nextword_skip_nonletters

nextword_no_next_word:
    move  $v0, $zero        #Set ret val
    lw    $s1, 0($sp)      
    lw    $s0, 4($sp)     
    lw    $ra, 8($sp)    
    addi  $sp, $sp, 12  
    jr    $ra          

#### Do not move this separator.
	
    
wordsmatch:
    addi  $sp, $sp, -12     #allocate stack space 
    sw    $ra, 8($sp)
    sw    $s0, 4($sp) 
    sw    $s1, 0($sp) 

    move  $s0, $a0          #$s0 = pointer to first word
    move  $s1, $a1          #$s1 = pointer to second word

wordsmatch_loop:
    lb    $t2, 0($s0)       #Load byte from first word
    lb    $t3, 0($s1)       #Load byte from second word

    #Check if both chars are letters
    move  $a0, $t2
    jal   isletter
    move  $t4, $v0          # $t4 = isword1_char_letter

    move  $a0, $t3
    jal   isletter
    move  $t5, $v0          # $t5 = isword2_char_letter

    #If neither char is letter, words have ended and matched
    beq   $t4, $zero, wordsmatch_check_end1
    beq   $t5, $zero, wordsmatch_check_end2

    #both letters, comp & continue
    move  $a0, $t2
    move  $a1, $t3
    jal   lettersmatch
    beq   $v0, $zero, wordsmatch_not_equal  

    #Continue loop
    addi  $s0, $s0, 1
    addi  $s1, $s1, 1
    j     wordsmatch_loop

wordsmatch_check_end1:
    #first word char not letter, check second
    beq   $t5, $zero, wordsmatch_match_end 
    j     wordsmatch_not_equal            

wordsmatch_check_end2:
    #Second word char not letter, check first
    beq   $t4, $zero, wordsmatch_match_end  
    j     wordsmatch_not_equal             

wordsmatch_match_end:
    li    $v0, 1         #set ret val to match
    j     wordsmatch_exit

wordsmatch_not_equal:
    li    $v0, 0         #set ret val to no match
    j     wordsmatch_exit

wordsmatch_exit:
    lw    $s1, 0($sp) 
    lw    $s0, 4($sp) 
    lw    $ra, 8($sp) 
    addi  $sp, $sp, 12
    jr    $ra        
	
#### Do not move this separator.
	
main:
	# save to stack
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
	########################################
	la  $s0, isletter_tests

	# isletter(@) = 0
	lbu $a0, 0($s0)
	jal isletter_test

 	# isletter(A) = 1
 	lbu $a0, 1($s0)
 	jal isletter_test
 
	# isletter(z) = 1
 	lbu $a0, 2($s0)
	jal isletter_test
 
	# isletter({) = 0
 	lbu $a0, 3($s0)
	jal isletter_test
 
	# isletter(Z) = 1
 	lbu $a0, 4($s0)
	jal isletter_test
 
	# isletter([) = 0
 	lbu $a0, 5($s0)
	jal isletter_test
 
	# isletter(a) = 1
 	lbu $a0, 6($s0)
	jal isletter_test
 
	# isletter(`) = 0
 	lbu $a0, 7($s0)
	jal isletter_test
	
 	########################################
 	la  $s0, lettersmatch_tests
 
	# lettersmatch(X, X) = 1
	lbu $a0, 0($s0)
	lbu $a1, 1($s0)
	jal lettersmatch_test
 
	# lettersmatch(X, x) = 1
	lbu $a0, 2($s0)
	lbu $a1, 3($s0)
	jal lettersmatch_test
 
	# lettersmatch(b, a) = 0
	lbu $a0, 4($s0)
	lbu $a1, 5($s0)
	jal lettersmatch_test
 
	# lettersmatch(m, M) = 1
	lbu $a0, 6($s0)
	lbu $a1, 7($s0)
	jal lettersmatch_test
 
	# lettersmatch(e, a) = 0
	lbu $a0, 8($s0)
	lbu $a1, 9($s0)
	jal lettersmatch_test

	# lettersmatch(C, N) = 0
	lbu $a0, 10($s0)
	lbu $a1, 11($s0)
	jal lettersmatch_test

	# lettersmatch(D, d) = 1
	lbu $a0, 12($s0)
	lbu $a1, 13($s0)
	jal lettersmatch_test
	
 	########################################
 	la  $s0, dogbitesman

	# nextword(pointer to "Dog bites man.") = pointer to "bites man."
	addi $a0, $s0, 0
	jal nextword_test

	# nextword(pointer to "og bites man.") = pointer to "bites man."
	addi $a0, $s0, 1
	jal nextword_test

	# nextword(pointer to "g bites man.") = pointer to "bites man."
	addi $a0, $s0, 2
	jal nextword_test

	# nextword(pointer to " bites man.") = pointer to "bites man."
	addi $a0, $s0, 3
	jal nextword_test

	# nextword(pointer to "man.") = 0
	addi $a0, $s0, 10
	jal nextword_test

	# nextword(pointer to ".") = 0
	addi $a0, $s0, 13
	jal nextword_test
	
 	la  $s0, dogbitesman2

	# nextword(pointer to "Dog-bites&2man!!") = pointer to "bites&2man!!"
	addi $a0, $s0, 0
	jal nextword_test

	# nextword(pointer to "ites&2man!!") = pointer to "man!!"
	addi $a0, $s0, 5
	jal nextword_test

	# nextword(pointer to "2man!!") = pointer to "man!!"
	addi $a0, $s0, 10
	jal nextword_test

	# nextword(pointer to "an!!") = 0
	addi $a0, $s0, 12
	jal nextword_test

	# nextword(pointer to "!!") = 0
	addi $a0, $s0, 14
	jal nextword_test
	
 	########################################
 	la  $s0, dogbitesman
 	la  $s1, dogbitesman2

	# wordsmatch("Dog bites man.", "Dog-bites&2man!!") = 1
	addi $a0, $s0, 0
	addi $a1, $s1, 0
	jal wordsmatch_test

	# wordsmatch("bites man.", "bites&2man!!") = 1
	addi $a0, $s0, 4
	addi $a1, $s1, 4
	jal wordsmatch_test

	# wordsmatch("man.", "man!!") = 1
	addi $a0, $s0, 10
	addi $a1, $s1, 11
	jal wordsmatch_test

	# wordsmatch("an.", "man!!") = 0
	addi $a0, $s0, 11
	addi $a1, $s1, 11
	jal wordsmatch_test

	# wordsmatch("an.", "an!!") = 1
	addi $a0, $s0, 11
	addi $a1, $s1, 12
	jal wordsmatch_test
	
	# wordsmatch("Dog bites man.", "bites&2man!!") = 0
	addi $a0, $s0, 0
	addi $a1, $s1, 4
	jal wordsmatch_test

	# wordsmatch("Dog bites man.", "man!!") = 0
	addi $a0, $s0, 0
	addi $a1, $s1, 11
	jal wordsmatch_test

	# wordsmatch("man.", "Dog-bites&2man!!") = 0
	addi $a0, $s0, 10
	addi $a1, $s1, 0
	jal wordsmatch_test

 	la  $s0, dogbitesman
 	la  $s1, manbitesdog
	
	# wordsmatch("Dog bites man.", "Man bites dog.") = 0
 	addi $a0, $s0, 0
 	addi $a1, $s1, 0
 	jal wordsmatch_test

	# wordsmatch("Dog bites man.", "dog.") = 1
 	addi $a0, $s0, 0
 	addi $a1, $s1, 10
 	jal wordsmatch_test

	# wordsmatch("man.", "dog.") = 0
 	addi $a0, $s0, 10
 	addi $a1, $s1, 10
 	jal wordsmatch_test

	# wordsmatch("bites man.", "bites dog.") = 1
 	addi $a0, $s0, 4
 	addi $a1, $s1, 4
 	jal wordsmatch_test
	
	# restore from stack 
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12

	# return
	jr $ra
	
# print space to console
print_space:
	li $a0, 32
	li $v0, 11
	syscall
	jr $ra

# print newline to console
print_newline:
	li $a0, 10
	li $v0, 11
	syscall
	jr $ra

# print char to console
print_char:
	li $v0, 11
	syscall
	jr $ra
	
# print string to console
print_string:	
	li $v0, 4
	syscall
	jr $ra

# print int to console
print_int:	
	li $v0, 1
	syscall
	jr $ra
	
# same arguments as isletter, no return value
isletter_test:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	
 	# s0: char
 	move $s0, $a0

	# print msg1
	la $a0, isletter_test_msg1
	jal print_string
 	
 	# print input char
 	move $a0, $s0
 	jal print_char

	# print msg2
	la $a0, isletter_test_msg2
	jal print_string
 	
 	# call isletter
 	move $a0, $s0
 	jal isletter
 
 	# print result
 	move $a0, $v0 
 	jal print_int
 	jal print_newline

	lw $ra, 0($sp)
	lw $s0, 4($sp)
	addi $sp, $sp, 8
	jr $ra
	
# same arguments as lettersmatch, no return value
lettersmatch_test:	
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
 	# s0, s1: chars
 	move $s0, $a0
	move $s1, $a1

	# print msg1
	la $a0, lettersmatch_test_msg1
	jal print_string
 	
 	# print input char
 	move $a0, $s0
 	jal print_char

	# print msg2
	la $a0, lettersmatch_test_msg2
	jal print_string

 	# print other input char
 	move $a0, $s1
 	jal print_char
 	
	# print msg3
	la $a0, lettersmatch_test_msg3
	jal print_string

 	# call lettersmatch
 	move $a0, $s0
 	move $a1, $s1
 	jal lettersmatch
 
 	# print result
 	move $a0, $v0 
 	jal print_int
 	jal print_newline

	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra
	
# same arguments as nextword, no return value
nextword_test:	
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	
 	# s0: argument string
 	move $s0, $a0

	# print msg1
	la $a0, nextword_test_msg1
	jal print_string
 	
 	# print input string
 	move $a0, $s0
 	jal print_string

	# print msg2
	la $a0, nextword_test_msg2
	jal print_string

 	# call nextword
 	move $a0, $s0
 	jal nextword
	beqz $v0, nextword_test_zero

	# print returned string
	move $s0, $v0
	la $a0, nextword_test_msg3
	jal print_string
 	move $a0, $s0
 	jal print_string
	la $a0, nextword_test_msg4
	jal print_string
 	jal print_newline
	b nextword_test_return

	# print 0 and be done
nextword_test_zero:
	li $a0, 0
	jal print_int
 	jal print_newline

nextword_test_return:	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	addi $sp, $sp, 8
	jr $ra
	
# same arguments as wordsmatch, no return value
wordsmatch_test:	
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
 	# s0, s1: strings
 	move $s0, $a0
	move $s1, $a1

	# print msg1
	la $a0, wordsmatch_test_msg1
	jal print_string
 	
 	# print input char
 	move $a0, $s0
 	jal print_string

	# print msg2
	la $a0, wordsmatch_test_msg2
	jal print_string

 	# print other input char
 	move $a0, $s1
 	jal print_string
 	
	# print msg3
	la $a0, wordsmatch_test_msg3
	jal print_string

 	# call wordsmatch
 	move $a0, $s0
 	move $a1, $s1
 	jal wordsmatch
 
 	# print result
 	move $a0, $v0 
 	jal print_int
 	jal print_newline

	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra
	
.data

isletter_test_msg1:	.asciiz "isletter("
isletter_test_msg2:	.asciiz ") = "

isletter_tests:	.asciiz "@Az{Z[a`"

lettersmatch_test_msg1:	.asciiz "lettersmatch("
lettersmatch_test_msg2:	.asciiz ", "
lettersmatch_test_msg3:	.asciiz ") = "

lettersmatch_tests:	.asciiz "XXXxbamMeaCNDd"

manbitesdog:	.asciiz "Man bites dog."
dogbitesman:	.asciiz "Dog bites man."
dogbitesman2:	.asciiz "Dog-bites&2man!!"

nextword_test_msg1:	.asciiz "nextword(pointer to \""
nextword_test_msg2:	.asciiz "\") = "
nextword_test_msg3:	.asciiz "pointer to \""	
nextword_test_msg4:	.asciiz "\""

wordsmatch_test_msg1:	.asciiz "wordsmatch(\""
wordsmatch_test_msg2:	.asciiz "\", \""
wordsmatch_test_msg3:	.asciiz "\") = "
	
