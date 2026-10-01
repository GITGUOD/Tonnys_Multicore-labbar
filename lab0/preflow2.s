	.file	"preflow2.c"
	.text
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC0:
	.string	"preflow2.c"
.LC1:
	.string	"d >= 0"
.LC2:
	.string	"u->e >= 0"
.LC3:
	.string	"abs(e->f) <= e->c"
	.text
	.p2align 4
	.type	push, @function
push:
.LFB64:
	.cfi_startproc
	subq	$8, %rsp
	.cfi_def_cfa_offset 16
	movq	%rsi, %rax
	movq	%rdx, %rsi
	movq	%rcx, %rdx
	movl	hello(%rip), %ecx
	andl	$13107, %ecx
	cmpq	%rax, (%rdx)
	movl	%ecx, hello(%rip)
	movl	4(%rax), %r8d
	movl	20(%rdx), %ecx
	movl	16(%rdx), %r9d
	je	.L15
	addl	%r9d, %ecx
	cmpl	%ecx, %r8d
	jle	.L16
	movl	20(%rdx), %r8d
	movl	16(%rdx), %ecx
	addl	%ecx, %r8d
	movl	%r8d, %ecx
.L7:
	lock subl	%ecx, 16(%rdx)
.L5:
	movl	hello(%rip), %r9d
	andl	$17476, %r9d
	movl	%r9d, hello(%rip)
	lock subl	%ecx, 4(%rax)
	lock addl	%ecx, 4(%rsi)
	testl	%r8d, %r8d
	js	.L17
	movl	4(%rax), %ecx
	testl	%ecx, %ecx
	js	.L18
	movl	16(%rdx), %ecx
	movl	20(%rdx), %r9d
	movl	%ecx, %edx
	negl	%edx
	cmovs	%ecx, %edx
	cmpl	%r9d, %edx
	jg	.L19
	movl	4(%rax), %edx
	testl	%edx, %edx
	jle	.L11
	cmpq	32(%rdi), %rax
	je	.L11
	cmpq	24(%rdi), %rax
	je	.L11
	movq	40(%rdi), %rdx
	movq	%rdx, 16(%rax)
	movq	%rax, 40(%rdi)
.L11:
	movl	4(%rsi), %eax
	cmpl	%r8d, %eax
	je	.L20
.L1:
	addq	$8, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	ret
	.p2align 4,,10
	.p2align 3
.L16:
	.cfi_restore_state
	movl	4(%rax), %ecx
	movl	%ecx, %r8d
	jmp	.L7
	.p2align 4,,10
	.p2align 3
.L20:
	cmpq	32(%rdi), %rsi
	je	.L1
	cmpq	24(%rdi), %rsi
	je	.L1
	movq	40(%rdi), %rax
	movq	%rax, 16(%rsi)
	movq	%rsi, 40(%rdi)
	addq	$8, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	ret
	.p2align 4,,10
	.p2align 3
.L15:
	.cfi_restore_state
	subl	%r9d, %ecx
	cmpl	%ecx, %r8d
	jle	.L21
	movl	20(%rdx), %r8d
	movl	16(%rdx), %ecx
	subl	%ecx, %r8d
	movl	%r8d, %ecx
.L4:
	lock addl	%ecx, 16(%rdx)
	jmp	.L5
	.p2align 4,,10
	.p2align 3
.L21:
	movl	4(%rax), %ecx
	movl	%ecx, %r8d
	jmp	.L4
.L19:
	leaq	__PRETTY_FUNCTION__.0(%rip), %rcx
	movl	$394, %edx
	leaq	.LC0(%rip), %rsi
	leaq	.LC3(%rip), %rdi
	call	__assert_fail@PLT
.L17:
	leaq	__PRETTY_FUNCTION__.0(%rip), %rcx
	movl	$392, %edx
	leaq	.LC0(%rip), %rsi
	leaq	.LC1(%rip), %rdi
	call	__assert_fail@PLT
.L18:
	leaq	__PRETTY_FUNCTION__.0(%rip), %rcx
	movl	$393, %edx
	leaq	.LC0(%rip), %rsi
	leaq	.LC2(%rip), %rdi
	call	__assert_fail@PLT
	.cfi_endproc
.LFE64:
	.size	push, .-push
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
	jmp	.L23
	.p2align 4,,10
	.p2align 3
.L24:
	leal	(%rbx,%rbx,4), %edx
	leal	-48(%rax,%rdx,2), %ebx
.L23:
	movq	stdin(%rip), %rdi
	movq	(%r12), %rbp
	call	getc@PLT
	movslq	%eax, %rdx
	testb	$8, 1(%rbp,%rdx,2)
	jne	.L24
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
	.section	.rodata.str1.1
.LC4:
	.string	"%s: "
.LC5:
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
	je	.L27
	movaps	%xmm0, 8288(%rsp)
	movaps	%xmm1, 8304(%rsp)
	movaps	%xmm2, 8320(%rsp)
	movaps	%xmm3, 8336(%rsp)
	movaps	%xmm4, 8352(%rsp)
	movaps	%xmm5, 8368(%rsp)
	movaps	%xmm6, 8384(%rsp)
	movaps	%xmm7, 8400(%rsp)
.L27:
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
	je	.L28
	movq	stderr(%rip), %rdi
	leaq	.LC4(%rip), %rdx
	movl	$2, %esi
	xorl	%eax, %eax
	call	__fprintf_chk@PLT
.L28:
	movq	stderr(%rip), %rdi
	movq	%rbx, %rcx
	movl	$2, %esi
	xorl	%eax, %eax
	leaq	.LC5(%rip), %rdx
	call	__fprintf_chk@PLT
	movl	$1, %edi
	call	exit@PLT
	.cfi_endproc
.LFE55:
	.size	error, .-error
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align 8
.LC6:
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
	je	.L37
	movq	%rbx, %rcx
	movq	%rbx, %rdx
	movq	%rax, %rdi
	xorl	%esi, %esi
	call	__memset_chk@PLT
	popq	%rbx
	.cfi_remember_state
	.cfi_def_cfa_offset 8
	ret
.L37:
	.cfi_restore_state
	movq	%rbx, %rsi
	leaq	.LC6(%rip), %rdi
	xorl	%eax, %eax
	call	error
	.cfi_endproc
.LFE71:
	.size	xcalloc.constprop.0, .-xcalloc.constprop.0
	.p2align 4
	.globl	preflow
	.type	preflow, @function
preflow:
.LFB67:
	.cfi_startproc
	endbr64
	pushq	%r12
	.cfi_def_cfa_offset 16
	.cfi_offset 12, -16
	pushq	%rbp
	.cfi_def_cfa_offset 24
	.cfi_offset 6, -24
	pushq	%rbx
	.cfi_def_cfa_offset 32
	.cfi_offset 3, -32
	movq	24(%rdi), %rbp
	movq	%rdi, %rbx
	movl	(%rdi), %eax
	xchgl	0(%rbp), %eax
	movq	8(%rbp), %r12
	testq	%r12, %r12
	jne	.L39
	jmp	.L44
	.p2align 4,,10
	.p2align 3
.L42:
	movq	%rbp, %rsi
	movq	%rbx, %rdi
	call	push
	testq	%r12, %r12
	je	.L44
.L39:
	movq	(%r12), %rcx
	movq	8(%r12), %r12
	movl	20(%rcx), %eax
	lock addl	%eax, 4(%rbp)
	movq	(%rcx), %rdx
	cmpq	%rdx, %rbp
	jne	.L42
	movq	8(%rcx), %rdx
	movq	%rbp, %rsi
	movq	%rbx, %rdi
	call	push
	testq	%r12, %r12
	jne	.L39
.L44:
	movq	40(%rbx), %rsi
	testq	%rsi, %rsi
	je	.L41
.L40:
	movq	16(%rsi), %rax
	movq	%rax, 40(%rbx)
	movq	8(%rsi), %rax
	.p2align 4,,10
	.p2align 3
.L71:
	testq	%rax, %rax
	je	.L48
	movq	(%rax), %rcx
	movl	$-1, %r9d
	movq	8(%rax), %rax
	movq	(%rcx), %rdx
	cmpq	%rsi, %rdx
	je	.L72
.L45:
	movl	(%rsi), %r8d
	movl	(%rdx), %edi
	cmpl	%edi, %r8d
	jle	.L71
	movl	16(%rcx), %edi
	imull	%r9d, %edi
	movl	20(%rcx), %r8d
	cmpl	%r8d, %edi
	jge	.L71
	testq	%rdx, %rdx
	je	.L48
	movq	%rbx, %rdi
	call	push
	movq	40(%rbx), %rsi
.L50:
	testq	%rsi, %rsi
	jne	.L40
.L41:
	movq	32(%rbx), %rax
	movl	4(%rax), %eax
	popq	%rbx
	.cfi_remember_state
	.cfi_def_cfa_offset 24
	popq	%rbp
	.cfi_def_cfa_offset 16
	popq	%r12
	.cfi_def_cfa_offset 8
	ret
	.p2align 4,,10
	.p2align 3
.L72:
	.cfi_restore_state
	movq	8(%rcx), %rdx
	movl	$1, %r9d
	jmp	.L45
	.p2align 4,,10
	.p2align 3
.L48:
	lock addl	$1, (%rsi)
	cmpq	%rsi, 32(%rbx)
	je	.L73
	movq	40(%rbx), %rax
	cmpq	%rsi, 24(%rbx)
	je	.L54
	movq	%rax, 16(%rsi)
	jmp	.L40
.L73:
	movq	40(%rbx), %rsi
	jmp	.L50
.L54:
	movq	%rax, %rsi
	jmp	.L50
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
	subq	$40, %rsp
	.cfi_def_cfa_offset 96
	movq	(%rsi), %rax
	movq	%rax, progname(%rip)
	movq	stdin(%rip), %rax
	movq	%rax, 24(%rsp)
	xorl	%eax, %eax
	call	next_int
	movslq	%eax, %rbx
	xorl	%eax, %eax
	call	next_int
	movl	%eax, %ebp
	xorl	%eax, %eax
	call	next_int
	xorl	%eax, %eax
	call	next_int
	movl	$48, %edi
	call	malloc@PLT
	testq	%rax, %rax
	je	.L98
	movl	%ebx, (%rax)
	movq	%rbx, %rdi
	movq	%rax, %r14
	movslq	%ebp, %r13
	movl	%ebp, 4(%rax)
	call	xcalloc.constprop.0
	movq	%r13, %rdi
	movq	%rax, 8(%r14)
	movq	%rax, %r12
	call	xcalloc.constprop.0
	movq	%r12, 24(%r14)
	movq	%rax, 16(%r14)
	leaq	(%rbx,%rbx,2), %rax
	leaq	-24(%r12,%rax,8), %rax
	movq	$0, 40(%r14)
	movq	%rax, 32(%r14)
	testl	%ebp, %ebp
	jle	.L76
	call	__ctype_b_loc@PLT
	leaq	0(%r13,%r13,2), %r15
	movq	$0, 8(%rsp)
	movq	%rax, %r12
	leaq	0(,%r15,8), %rax
	movq	%rax, 16(%rsp)
	.p2align 4,,10
	.p2align 3
.L77:
	xorl	%ebx, %ebx
	jmp	.L85
	.p2align 4,,10
	.p2align 3
.L78:
	leal	(%rbx,%rbx,4), %edx
	leal	-48(%rax,%rdx,2), %ebx
.L85:
	movq	stdin(%rip), %rdi
	movq	(%r12), %rbp
	call	getc@PLT
	movslq	%eax, %rdx
	testb	$8, 1(%rbp,%rdx,2)
	jne	.L78
	xorl	%ebp, %ebp
	jmp	.L79
	.p2align 4,,10
	.p2align 3
.L80:
	leal	0(%rbp,%rbp,4), %edx
	leal	-48(%rax,%rdx,2), %ebp
.L79:
	movq	stdin(%rip), %rdi
	movq	(%r12), %r13
	call	getc@PLT
	movslq	%eax, %rcx
	testb	$8, 1(%r13,%rcx,2)
	jne	.L80
	xorl	%r13d, %r13d
	jmp	.L81
	.p2align 4,,10
	.p2align 3
.L82:
	leal	0(%r13,%r13,4), %edx
	leal	-48(%rax,%rdx,2), %r13d
.L81:
	movq	stdin(%rip), %rdi
	movq	(%r12), %r15
	call	getc@PLT
	movslq	%eax, %rsi
	testb	$8, 1(%r15,%rsi,2)
	jne	.L82
	movq	8(%r14), %rax
	movslq	%ebx, %rbx
	movslq	%ebp, %rbp
	leaq	(%rbx,%rbx,2), %rcx
	leaq	0(%rbp,%rbp,2), %rsi
	movq	8(%rsp), %rbp
	addq	16(%r14), %rbp
	leaq	(%rax,%rcx,8), %r15
	leaq	(%rax,%rsi,8), %rbx
	movq	%r15, 0(%rbp)
	movq	%rbx, 8(%rbp)
	xchgl	20(%rbp), %r13d
	movl	$16, %edi
	call	malloc@PLT
	testq	%rax, %rax
	je	.L84
	movq	%rbp, %xmm0
	movl	$16, %edi
	movhps	8(%r15), %xmm0
	movups	%xmm0, (%rax)
	movq	%rax, 8(%r15)
	call	malloc@PLT
	testq	%rax, %rax
	je	.L84
	movq	%rbp, %xmm0
	addq	$24, 8(%rsp)
	movhps	8(%rbx), %xmm0
	movups	%xmm0, (%rax)
	movq	%rax, 8(%rbx)
	movq	8(%rsp), %rax
	cmpq	%rax, 16(%rsp)
	jne	.L77
.L76:
	movq	24(%rsp), %rdi
	call	fclose@PLT
	movq	%r14, %rdi
	call	preflow
	leaq	.LC7(%rip), %rsi
	movl	$2, %edi
	movl	%eax, %edx
	xorl	%eax, %eax
	call	__printf_chk@PLT
	movslq	(%r14), %rax
	movq	8(%r14), %r13
	testl	%eax, %eax
	jle	.L89
	leaq	8(%r13), %rbp
	leaq	(%rax,%rax,2), %rax
	leaq	0(%rbp,%rax,8), %r12
	.p2align 4,,10
	.p2align 3
.L88:
	movq	0(%rbp), %rbx
	testq	%rbx, %rbx
	je	.L90
	.p2align 4,,10
	.p2align 3
.L87:
	movq	%rbx, %rdi
	movq	8(%rbx), %rbx
	call	free@PLT
	testq	%rbx, %rbx
	jne	.L87
.L90:
	addq	$24, %rbp
	cmpq	%rbp, %r12
	jne	.L88
.L89:
	movq	%r13, %rdi
	call	free@PLT
	movq	16(%r14), %rdi
	call	free@PLT
	movq	%r14, %rdi
	call	free@PLT
	addq	$40, %rsp
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
.L84:
	.cfi_restore_state
	movl	$16, %esi
	leaq	.LC6(%rip), %rdi
	xorl	%eax, %eax
	call	error
.L98:
	movl	$48, %esi
	leaq	.LC6(%rip), %rdi
	xorl	%eax, %eax
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
