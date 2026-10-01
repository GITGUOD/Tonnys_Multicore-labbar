	.file	"preflow.c"
	.text
	.p2align 4
	.type	next_int, @function
next_int:
.LFB56:
	.cfi_startproc
	pushq	%r12
	.cfi_def_cfa_offset 16
	.cfi_offset 12, -16
	pushq	%rbp
	.cfi_def_cfa_offset 24
	.cfi_offset 6, -24
	pushq	%rbx
	.cfi_def_cfa_offset 32
	.cfi_offset 3, -32
	xorl	%ebx, %ebx
	call	__ctype_b_loc@PLT
	movq	%rax, %r12
	jmp	.L2
	.p2align 4,,10
	.p2align 3
.L3:
	leal	(%rbx,%rbx,4), %edx
	leal	-48(%rax,%rdx,2), %ebx
.L2:
	movq	stdin(%rip), %rdi
	movq	(%r12), %rbp
	call	getc@PLT
	movslq	%eax, %rdx
	testb	$8, 1(%rbp,%rdx,2)
	jne	.L3
	movl	%ebx, %eax
	popq	%rbx
	.cfi_def_cfa_offset 24
	popq	%rbp
	.cfi_def_cfa_offset 16
	popq	%r12
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE56:
	.size	next_int, .-next_int
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"%s: "
.LC1:
	.string	"error: %s\n"
	.text
	.p2align 4
	.globl	error
	.type	error, @function
error:
.LFB55:
	.cfi_startproc
	endbr64
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	subq	$4096, %rsp
	.cfi_def_cfa_offset 4112
	orq	$0, (%rsp)
	subq	$4096, %rsp
	.cfi_def_cfa_offset 8208
	orq	$0, (%rsp)
	subq	$224, %rsp
	.cfi_def_cfa_offset 8432
	movq	%rsi, 8248(%rsp)
	movq	%rdx, 8256(%rsp)
	movq	%rcx, 8264(%rsp)
	movq	%r8, 8272(%rsp)
	movq	%r9, 8280(%rsp)
	testb	%al, %al
	je	.L7
	movaps	%xmm0, 8288(%rsp)
	movaps	%xmm1, 8304(%rsp)
	movaps	%xmm2, 8320(%rsp)
	movaps	%xmm3, 8336(%rsp)
	movaps	%xmm4, 8352(%rsp)
	movaps	%xmm5, 8368(%rsp)
	movaps	%xmm6, 8384(%rsp)
	movaps	%xmm7, 8400(%rsp)
.L7:
	movq	%fs:40, %rax
	movq	%rax, 8232(%rsp)
	xorl	%eax, %eax
	leaq	32(%rsp), %rbx
	movq	%rdi, %rcx
	leaq	8(%rsp), %r8
	leaq	8432(%rsp), %rax
	movl	$8192, %edx
	movl	$2, %esi
	movq	%rbx, %rdi
	movq	%rax, 16(%rsp)
	leaq	8240(%rsp), %rax
	movl	$8, 8(%rsp)
	movl	$48, 12(%rsp)
	movq	%rax, 24(%rsp)
	call	__vsprintf_chk@PLT
	movq	progname(%rip), %rcx
	testq	%rcx, %rcx
	je	.L8
	movq	stderr(%rip), %rdi
	leaq	.LC0(%rip), %rdx
	movl	$2, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
.L8:
	movq	stderr(%rip), %rdi
	movq	%rbx, %rcx
	movl	$2, %esi
	xorl	%eax, %eax
	leaq	.LC1(%rip), %rdx
	call	__fprintf_chk@PLT
	movl	$1, %edi
	call	exit@PLT
	.cfi_endproc
.LFE55:
	.size	error, .-error
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align 8
.LC2:
	.string	"out of memory: malloc(%zu) failed"
	.text
	.p2align 4
	.type	xcalloc.constprop.0, @function
xcalloc.constprop.0:
.LFB71:
	.cfi_startproc
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	leaq	(%rdi,%rdi,2), %rbx
	salq	$3, %rbx
	movq	%rbx, %rdi
	call	malloc@PLT
	testq	%rax, %rax
	je	.L17
	movq	%rbx, %rcx
	movq	%rbx, %rdx
	movq	%rax, %rdi
	xorl	%esi, %esi
	call	__memset_chk@PLT
	popq	%rbx
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	ret
.L17:
	.cfi_restore_state
	movq	%rbx, %rsi
	leaq	.LC2(%rip), %rdi
	xorl	%eax, %eax
	call	error
	.cfi_endproc
.LFE71:
	.size	xcalloc.constprop.0, .-xcalloc.constprop.0
	.section	.rodata.str1.1
.LC3:
	.string	"preflow.c"
.LC4:
	.string	"d >= 0"
.LC5:
	.string	"u->e >= 0"
.LC6:
	.string	"abs(e->f) <= e->c"
	.text
	.p2align 4
	.globl	preflow
	.type	preflow, @function
preflow:
.LFB67:
	.cfi_startproc
	endbr64
	pushq	%r14
	.cfi_def_cfa_offset 16
	.cfi_offset 14, -16
	movq	%rdi, %r9
	pushq	%r13
	.cfi_def_cfa_offset 24
	.cfi_offset 13, -24
	pushq	%r12
	.cfi_def_cfa_offset 32
	.cfi_offset 12, -32
	pushq	%rbp
	.cfi_def_cfa_offset 40
	.cfi_offset 6, -40
	pushq	%rbx
	.cfi_def_cfa_offset 48
	.cfi_offset 3, -48
	movq	24(%rdi), %r8
	movl	(%rdi), %eax
	movq	8(%r8), %r10
	movl	%eax, (%r8)
	testq	%r10, %r10
	je	.L29
	movl	4(%r8), %eax
	jmp	.L28
	.p2align 4,,10
	.p2align 3
.L27:
	testq	%r10, %r10
	je	.L29
.L28:
	movq	(%r10), %rsi
	movq	8(%r10), %r10
	movl	20(%rsi), %r11d
	movq	(%rsi), %rdi
	movl	16(%rsi), %ecx
	addl	%r11d, %eax
	movl	%eax, 4(%r8)
	cmpq	%rdi, %r8
	je	.L22
	movl	hello(%rip), %edx
	andl	$13107, %edx
	movl	%edx, hello(%rip)
	leal	(%r11,%rcx), %edx
	cmpl	%eax, %edx
	cmovg	%eax, %edx
	subl	%edx, %ecx
.L23:
	subl	%edx, %eax
	movl	%ecx, 16(%rsi)
	movl	hello(%rip), %esi
	movl	%eax, 4(%r8)
	movl	4(%rdi), %ebx
	andl	$17476, %esi
	addl	%edx, %ebx
	movl	%esi, hello(%rip)
	movl	%ebx, 4(%rdi)
	testl	%edx, %edx
	js	.L37
	movl	4(%r8), %eax
	testl	%eax, %eax
	js	.L38
	movl	%ecx, %esi
	negl	%esi
	cmovns	%esi, %ecx
	cmpl	%ecx, %r11d
	jl	.L39
	cmpl	%ebx, %edx
	jne	.L27
	cmpq	%rdi, 32(%r9)
	je	.L27
	cmpq	%rdi, %r8
	je	.L27
	movq	40(%r9), %rdx
	movq	%rdx, 16(%rdi)
	movq	%rdi, 40(%r9)
	testq	%r10, %r10
	jne	.L28
	.p2align 4,,10
	.p2align 3
.L29:
	movq	40(%r9), %r10
	testq	%r10, %r10
	je	.L21
	movq	16(%r10), %rbx
	movq	8(%r10), %rbp
	movl	(%r10), %r11d
.L20:
	movq	%rbx, 40(%r9)
	movq	%rbx, %r12
	movq	%rbp, %rax
	testq	%rbp, %rbp
	jne	.L33
	jmp	.L34
	.p2align 4,,10
	.p2align 3
.L30:
	cmpl	%r11d, (%rdi)
	jge	.L31
	imull	16(%rdx), %esi
	cmpl	20(%rdx), %esi
	jl	.L32
.L31:
	testq	%rax, %rax
	je	.L34
.L33:
	movq	(%rax), %rdx
	movl	$-1, %esi
	movq	8(%rax), %rax
	movq	(%rdx), %rcx
	movq	%rcx, %rdi
	cmpq	%r10, %rcx
	jne	.L30
	movq	8(%rdx), %rdi
	movl	$1, %esi
	jmp	.L30
	.p2align 4,,10
	.p2align 3
.L22:
	movl	hello(%rip), %edx
	movq	8(%rsi), %rdi
	andl	$13107, %edx
	movl	%edx, hello(%rip)
	movl	%r11d, %edx
	subl	%ecx, %edx
	cmpl	%eax, %edx
	cmovg	%eax, %edx
	addl	%edx, %ecx
	jmp	.L23
	.p2align 4,,10
	.p2align 3
.L32:
	testq	%rdi, %rdi
	je	.L34
	movl	hello(%rip), %eax
	movl	16(%rdx), %r14d
	movl	20(%rdx), %r13d
	movl	4(%r10), %esi
	andl	$13107, %eax
	movl	%eax, hello(%rip)
	cmpq	%r10, %rcx
	je	.L89
	leal	(%r14,%r13), %eax
	movl	%r14d, %ecx
	cmpl	%esi, %eax
	cmovg	%esi, %eax
	subl	%eax, %ecx
.L36:
	subl	%eax, %esi
	movl	%ecx, 16(%rdx)
	movl	hello(%rip), %edx
	movl	%esi, 4(%r10)
	movl	4(%rdi), %r14d
	andl	$17476, %edx
	addl	%eax, %r14d
	movl	%edx, hello(%rip)
	movl	%r14d, 4(%rdi)
	testl	%eax, %eax
	js	.L37
	movl	4(%r10), %esi
	testl	%esi, %esi
	js	.L38
	movl	%ecx, %edx
	negl	%edx
	cmovs	%ecx, %edx
	cmpl	%r13d, %edx
	jg	.L39
	testl	%esi, %esi
	je	.L43
	cmpq	%r10, 32(%r9)
	je	.L43
	cmpq	%r10, %r8
	je	.L43
	movq	%rbx, 16(%r10)
	movq	%r10, 40(%r9)
	cmpl	%r14d, %eax
	jne	.L20
	cmpq	%rdi, 32(%r9)
	je	.L20
	movq	%r10, %r12
	cmpq	%r8, %rdi
	je	.L20
.L46:
	movq	8(%rdi), %rbp
	movq	%r12, %rbx
	movq	%r12, 16(%rdi)
	movq	%rdi, %r10
	movl	(%rdi), %r11d
	movq	%rbx, %r12
	movq	%rbx, 40(%r9)
	movq	%rbp, %rax
	testq	%rbp, %rbp
	jne	.L33
	.p2align 4,,10
	.p2align 3
.L34:
	addl	$1, %r11d
	movl	%r11d, (%r10)
	cmpq	%r10, 32(%r9)
	je	.L42
	cmpq	%r10, %r8
	jne	.L20
	testq	%rbx, %rbx
	je	.L21
.L91:
	movq	%rbx, %r10
	movq	8(%r12), %rbp
	movq	16(%rbx), %rbx
	movl	(%r12), %r11d
	jmp	.L20
	.p2align 4,,10
	.p2align 3
.L43:
	cmpl	%r14d, %eax
	je	.L90
.L42:
	testq	%rbx, %rbx
	jne	.L91
.L21:
	movq	32(%r9), %rax
	popq	%rbx
	.cfi_remember_state
	.cfi_def_cfa_offset 40
	popq	%rbp
	.cfi_def_cfa_offset 32
	popq	%r12
	.cfi_def_cfa_offset 24
	movl	4(%rax), %eax
	popq	%r13
	.cfi_def_cfa_offset 16
	popq	%r14
	.cfi_def_cfa_offset 8
	ret
	.p2align 4,,10
	.p2align 3
.L89:
	.cfi_restore_state
	movl	%r13d, %eax
	subl	%r14d, %eax
	cmpl	%esi, %eax
	cmovg	%esi, %eax
	leal	(%rax,%r14), %ecx
	jmp	.L36
	.p2align 4,,10
	.p2align 3
.L90:
	cmpq	%rdi, 32(%r9)
	je	.L42
	cmpq	%r8, %rdi
	jne	.L46
	jmp	.L42
.L38:
	leaq	__PRETTY_FUNCTION__.0(%rip), %rcx
	movl	$390, %edx
	leaq	.LC3(%rip), %rsi
	leaq	.LC5(%rip), %rdi
	call	__assert_fail@PLT
.L37:
	leaq	__PRETTY_FUNCTION__.0(%rip), %rcx
	movl	$389, %edx
	leaq	.LC3(%rip), %rsi
	leaq	.LC4(%rip), %rdi
	call	__assert_fail@PLT
.L39:
	leaq	__PRETTY_FUNCTION__.0(%rip), %rcx
	movl	$391, %edx
	leaq	.LC3(%rip), %rsi
	leaq	.LC6(%rip), %rdi
	call	__assert_fail@PLT
	.cfi_endproc
.LFE67:
	.size	preflow, .-preflow
	.section	.rodata.str1.1
.LC7:
	.string	"f = %d\n"
	.section	.text.startup,"ax",@progbits
	.p2align 4
	.globl	main
	.type	main, @function
main:
.LFB69:
	.cfi_startproc
	endbr64
	pushq	%r15
	.cfi_def_cfa_offset 16
	.cfi_offset 15, -16
	pushq	%r14
	.cfi_def_cfa_offset 24
	.cfi_offset 14, -24
	pushq	%r13
	.cfi_def_cfa_offset 32
	.cfi_offset 13, -32
	pushq	%r12
	.cfi_def_cfa_offset 40
	.cfi_offset 12, -40
	pushq	%rbp
	.cfi_def_cfa_offset 48
	.cfi_offset 6, -48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	.cfi_offset 3, -56
	subq	$56, %rsp
	.cfi_def_cfa_offset 112
	movq	(%rsi), %rax
	movq	%rax, progname(%rip)
	movq	stdin(%rip), %rax
	movq	%rax, 32(%rsp)
	xorl	%eax, %eax
	call	next_int
	movslq	%eax, %r12
	xorl	%eax, %eax
	call	next_int
	movl	%eax, %ebp
	xorl	%eax, %eax
	call	next_int
	xorl	%eax, %eax
	call	next_int
	movl	$48, %edi
	call	malloc@PLT
	movq	%rax, 24(%rsp)
	testq	%rax, %rax
	je	.L117
	movl	%r12d, (%rax)
	movq	%r12, %rdi
	movq	%rax, %r15
	movslq	%ebp, %rbx
	movl	%ebp, 4(%rax)
	call	xcalloc.constprop.0
	movq	%rbx, %rdi
	movq	%rax, 8(%r15)
	movq	%rax, %r14
	movq	%rax, 8(%rsp)
	call	xcalloc.constprop.0
	movq	%r15, %rsi
	movq	%rax, 40(%rsp)
	movq	%rax, %r15
	movq	%rax, 16(%rsi)
	leaq	(%r12,%r12,2), %rax
	leaq	-24(%r14,%rax,8), %rax
	movq	%r14, 24(%rsi)
	movq	%rax, 32(%rsi)
	movq	$0, 40(%rsi)
	testl	%ebp, %ebp
	jle	.L94
	call	__ctype_b_loc@PLT
	movq	%r15, %r13
	movq	%rax, %r12
	leaq	(%rbx,%rbx,2), %rax
	leaq	(%r15,%rax,8), %rax
	movq	%rax, 16(%rsp)
	.p2align 4,,10
	.p2align 3
.L95:
	xorl	%ebx, %ebx
	jmp	.L103
	.p2align 4,,10
	.p2align 3
.L96:
	leal	(%rbx,%rbx,4), %edx
	leal	-48(%rax,%rdx,2), %ebx
.L103:
	movq	stdin(%rip), %rdi
	movq	(%r12), %rbp
	call	getc@PLT
	movslq	%eax, %rdx
	testb	$8, 1(%rbp,%rdx,2)
	jne	.L96
	xorl	%ebp, %ebp
	jmp	.L97
	.p2align 4,,10
	.p2align 3
.L98:
	leal	0(%rbp,%rbp,4), %edx
	leal	-48(%rax,%rdx,2), %ebp
.L97:
	movq	stdin(%rip), %rdi
	movq	(%r12), %r14
	call	getc@PLT
	movslq	%eax, %rcx
	testb	$8, 1(%r14,%rcx,2)
	jne	.L98
	xorl	%r14d, %r14d
	jmp	.L99
	.p2align 4,,10
	.p2align 3
.L100:
	leal	(%r14,%r14,4), %edx
	leal	-48(%rax,%rdx,2), %r14d
.L99:
	movq	stdin(%rip), %rdi
	movq	(%r12), %r15
	call	getc@PLT
	movslq	%eax, %rsi
	testb	$8, 1(%r15,%rsi,2)
	jne	.L100
	movq	8(%rsp), %rcx
	movslq	%ebx, %rbx
	movslq	%ebp, %rbp
	movl	%r14d, 20(%r13)
	leaq	(%rbx,%rbx,2), %rax
	movl	$16, %edi
	leaq	(%rcx,%rax,8), %r15
	leaq	0(%rbp,%rbp,2), %rax
	leaq	(%rcx,%rax,8), %rbx
	movq	%r15, 0(%r13)
	movq	%rbx, 8(%r13)
	call	malloc@PLT
	testq	%rax, %rax
	je	.L102
	movq	%r13, %xmm0
	movl	$16, %edi
	movhps	8(%r15), %xmm0
	movups	%xmm0, (%rax)
	movq	%rax, 8(%r15)
	call	malloc@PLT
	testq	%rax, %rax
	je	.L102
	movq	%r13, %xmm0
	addq	$24, %r13
	movhps	8(%rbx), %xmm0
	movups	%xmm0, (%rax)
	movq	%rax, 8(%rbx)
	movq	16(%rsp), %rax
	cmpq	%rax, %r13
	jne	.L95
.L94:
	movq	32(%rsp), %rdi
	call	fclose@PLT
	movq	24(%rsp), %rbx
	movq	%rbx, %rdi
	call	preflow
	leaq	.LC7(%rip), %rsi
	movl	$2, %edi
	movl	%eax, %edx
	xorl	%eax, %eax
	call	__printf_chk@PLT
	movslq	(%rbx), %rax
	testl	%eax, %eax
	jle	.L104
	movq	8(%rsp), %rsi
	leaq	(%rax,%rax,2), %rax
	leaq	8(%rsi), %rbp
	leaq	8(%rsi,%rax,8), %r12
	.p2align 4,,10
	.p2align 3
.L107:
	movq	0(%rbp), %rbx
	testq	%rbx, %rbx
	je	.L105
	.p2align 4,,10
	.p2align 3
.L106:
	movq	%rbx, %rdi
	movq	8(%rbx), %rbx
	call	free@PLT
	testq	%rbx, %rbx
	jne	.L106
.L105:
	addq	$24, %rbp
	cmpq	%r12, %rbp
	jne	.L107
.L104:
	movq	8(%rsp), %rdi
	call	free@PLT
	movq	40(%rsp), %rdi
	call	free@PLT
	movq	24(%rsp), %rdi
	call	free@PLT
	addq	$56, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 56
	xorl	%eax, %eax
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%rbp
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	ret
.L102:
	.cfi_restore_state
	movl	$16, %esi
	leaq	.LC2(%rip), %rdi
	xorl	%eax, %eax
	call	error
.L117:
	movl	$48, %esi
	leaq	.LC2(%rip), %rdi
	call	error
	.cfi_endproc
.LFE69:
	.size	main, .-main
	.section	.rodata
	.type	__PRETTY_FUNCTION__.0, @object
	.size	__PRETTY_FUNCTION__.0, 5
__PRETTY_FUNCTION__.0:
	.string	"push"
	.local	progname
	.comm	progname,8,8
	.globl	hello
	.bss
	.align 4
	.type	hello, @object
	.size	hello, 4
hello:
	.zero	4
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0"
	.section	.note.GNU-stack,"",@progbits
	.section	.note.gnu.property,"a"
	.align 8
	.long	1f - 0f
	.long	4f - 1f
	.long	5
0:
	.string	"GNU"
1:
	.align 8
	.long	0xc0000002
	.long	3f - 2f
2:
	.long	0x3
3:
	.align 8
4:
