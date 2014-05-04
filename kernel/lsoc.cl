/*-
 * Copyright 2009 Colin Percival, 2011 ArtForz, 2011 pooler, 2012 mtrlt,
 * 2012-2013 Con Kolivas.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * This file was originally written by Colin Percival as part of the Tarsnap
 * online backup system.
 *
 * V1.3 modified by sterling pickens linuxsociety.org 2014
 */

/* N (nfactor), CPU/Memory cost parameter */
__constant uint N[] = {
	0x00000001U,  /* never used, padding */
	0x00000002U,
	0x00000004U,
	0x00000008U,
	0x00000010U,
	0x00000020U,
	0x00000040U,
	0x00000080U,
	0x00000100U,
	0x00000200U,
	0x00000400U,  /* 2^10 == 1024, Litecoin scrypt default */
	0x00000800U,
	0x00001000U,
	0x00002000U,
	0x00004000U,
	0x00008000U,
	0x00010000U,
	0x00020000U,
	0x00040000U,
	0x00080000U,
	0x00100000U
};

/* Backwards compatibility, if NFACTOR not defined, default to 10 for scrypt */
#ifndef NFACTOR
#define NFACTOR 10
#endif

__constant uint ES[2] = { 0x00FF00FF, 0xFF00FF00 };

__constant uint K[] = {
	0x428a2f98U,
	0x71374491U,
	0xb5c0fbcfU,
	0xe9b5dba5U,
	0x3956c25bU,
	0x59f111f1U,
	0x923f82a4U,
	0xab1c5ed5U,
	0xd807aa98U,
	0x12835b01U,
	0x243185beU, // 10
	0x550c7dc3U,
	0x72be5d74U,
	0x80deb1feU,
	0x9bdc06a7U,
	0xe49b69c1U,
	0xefbe4786U,
	0x0fc19dc6U,
	0x240ca1ccU,
	0x2de92c6fU,
	0x4a7484aaU, // 20
	0x5cb0a9dcU,
	0x76f988daU,
	0x983e5152U,
	0xa831c66dU,
	0xb00327c8U,
	0xbf597fc7U,
	0xc6e00bf3U,
	0xd5a79147U,
	0x06ca6351U,
	0x14292967U, // 30
	0x27b70a85U,
	0x2e1b2138U,
	0x4d2c6dfcU,
	0x53380d13U,
	0x650a7354U,
	0x766a0abbU,
	0x81c2c92eU,
	0x92722c85U,
	0xa2bfe8a1U,
	0xa81a664bU, // 40
	0xc24b8b70U,
	0xc76c51a3U,
	0xd192e819U,
	0xd6990624U,
	0xf40e3585U,
	0x106aa070U,
	0x19a4c116U,
	0x1e376c08U,
	0x2748774cU,
	0x34b0bcb5U, // 50
	0x391c0cb3U,
	0x4ed8aa4aU,
	0x5b9cca4fU,
	0x682e6ff3U,
	0x748f82eeU,
	0x78a5636fU,
	0x84c87814U,
	0x8cc70208U,
	0x90befffaU,
	0xa4506cebU, // 60
	0xbef9a3f7U,
	0xc67178f2U,
	0x98c7e2a2U,
	0xfc08884dU,
	0xcd2a11aeU,
	0x510e527fU,
	0x9b05688cU,
	0xC3910C8EU,
	0xfb6feee7U,
	0x2a01a605U, // 70
	0x0c2e12e0U,
	0x4498517BU,
	0x6a09e667U,
	0xa4ce148bU,
	0x95F61999U,
	0xc19bf174U,
	0xBB67AE85U,
	0x3C6EF372U,
	0xA54FF53AU,
	0x1F83D9ABU, // 80
	0x5BE0CD19U,
	0x5C5C5C5CU,
	0x36363636U,
	0x80000000U,
//	0x000003FFU, //never used
	0x00000280U,
	0x000004a0U,
	0x00000300U
};

#define rotl(x,y) rotate(x,y)
#define Ch(x,y,z) bitselect(z,y,x)
#define Maj(x,y,z) Ch((x^z),y,z)

#define EndianSwapa(n) (Ch(ES[0], rotl(n, 8U), rotl(n, 24U)))
#define EndianSwapb(n) (rotl(n & ES[0], 24U)|rotl(n & ES[1], 8U))

#define Tr2(x)		(rotl(x, 30U) ^ rotl(x, 19U) ^ rotl(x, 10U))
#define Tr1(x)		(rotl(x, 26U) ^ rotl(x, 21U) ^ rotl(x, 7U))
#define Wr2(x)		(rotl(x, 25U) ^ rotl(x, 14U) ^ (x>>3U))
#define Wr1(x)		(rotl(x, 15U) ^ rotl(x, 13U) ^ (x>>10U))

#define RND(a, b, c, d, e, f, g, h, k)  \
	h += Tr1(e); 			\
	h += Ch(e, f, g); 		\
	h += k;				\
	d += h;				\
	h += Tr2(a); 			\
	h += Maj(a, b, c);

void SHA256(uint4*restrict state0,uint4*restrict state1, const uint4 block0, const uint4 block1, const uint4 block2, const uint4 block3, bool notfresh)
{
	uint4 S0 = *state0;
	uint4 S1 = *state1;
	
#define A S0.x
#define B S0.y
#define C S0.z
#define D S0.w
#define E S1.x
#define F S1.y
#define G S1.z
#define H S1.w

    uint4 W = block0;
    uint4 X = block1;
    uint4 Y = block2;
    uint4 Z = block3;

	if(notfresh){
		RND(A,B,C,D,E,F,G,H, W.x+ K[0]);
		RND(H,A,B,C,D,E,F,G, W.y+ K[1]);
		RND(G,H,A,B,C,D,E,F, W.z+ K[2]);
		RND(F,G,H,A,B,C,D,E, W.w+ K[3]);
	}else{
		D= K[63] +W.x;
		H= K[64] +W.x;
		C= K[65] +Tr1(D)+Ch(D, K[66], K[67])+W.y;
		G= K[68] +C+Tr2(H)+Ch(H, K[69] ,K[70]);
		B= K[71] +Tr1(C)+Ch(C,D,K[66])+W.z;
		F= K[72] +B+Tr2(G)+Maj(G,H, K[73]);
		A= K[74] +Tr1(B)+Ch(B,C,D)+W.w;
		E= K[75] +A+Tr2(F)+Maj(F,G,H);
	}
	RND(E,F,G,H,A,B,C,D, X.x+ K[4]);
	RND(D,E,F,G,H,A,B,C, X.y+ K[5]);
	RND(C,D,E,F,G,H,A,B, X.z+ K[6]);
	RND(B,C,D,E,F,G,H,A, X.w+ K[7]);

	RND(A,B,C,D,E,F,G,H, Y.x+ K[8]);
	RND(H,A,B,C,D,E,F,G, Y.y+ K[9]);
	RND(G,H,A,B,C,D,E,F, Y.z+ K[10]);
	RND(F,G,H,A,B,C,D,E, Y.w+ K[11]);

	RND(E,F,G,H,A,B,C,D, Z.x+ K[12]);
	RND(D,E,F,G,H,A,B,C, Z.y+ K[13]);
	RND(C,D,E,F,G,H,A,B, Z.z+ K[14]);
	RND(B,C,D,E,F,G,H,A, Z.w+ K[76]);

	W.x += Wr1(Z.z) + Y.y + Wr2(W.y);
	RND(A,B,C,D,E,F,G,H, W.x+ K[15]);
	W.y += Wr1(Z.w) + Y.z + Wr2(W.z);
	RND(H,A,B,C,D,E,F,G, W.y+ K[16]);
	W.z += Wr1(W.x) + Y.w + Wr2(W.w);
	RND(G,H,A,B,C,D,E,F, W.z+ K[17]);
	W.w += Wr1(W.y) + Z.x + Wr2(X.x);
	RND(F,G,H,A,B,C,D,E, W.w+ K[18]);

	X.x += Wr1(W.z) + Z.y + Wr2(X.y);
	RND(E,F,G,H,A,B,C,D, X.x+ K[19]);
	X.y += Wr1(W.w) + Z.z + Wr2(X.z);
	RND(D,E,F,G,H,A,B,C, X.y+ K[20]);
	X.z += Wr1(X.x) + Z.w + Wr2(X.w);
	RND(C,D,E,F,G,H,A,B, X.z+ K[21]);
	X.w += Wr1(X.y) + W.x + Wr2(Y.x);
	RND(B,C,D,E,F,G,H,A, X.w+ K[22]);

	Y.x += Wr1(X.z) + W.y + Wr2(Y.y);
	RND(A,B,C,D,E,F,G,H, Y.x+ K[23]);
	Y.y += Wr1(X.w) + W.z + Wr2(Y.z);
	RND(H,A,B,C,D,E,F,G, Y.y+ K[24]);
	Y.z += Wr1(Y.x) + W.w + Wr2(Y.w);
	RND(G,H,A,B,C,D,E,F, Y.z+ K[25]);
	Y.w += Wr1(Y.y) + X.x + Wr2(Z.x);
	RND(F,G,H,A,B,C,D,E, Y.w+ K[26]);

	Z.x += Wr1(Y.z) + X.y + Wr2(Z.y);
	RND(E,F,G,H,A,B,C,D, Z.x+ K[27]);
	Z.y += Wr1(Y.w) + X.z + Wr2(Z.z);
	RND(D,E,F,G,H,A,B,C, Z.y+ K[28]);
	Z.z += Wr1(Z.x) + X.w + Wr2(Z.w);
	RND(C,D,E,F,G,H,A,B, Z.z+ K[29]);
	Z.w += Wr1(Z.y) + Y.x + Wr2(W.x);
	RND(B,C,D,E,F,G,H,A, Z.w+ K[30]);

	W.x += Wr1(Z.z) + Y.y + Wr2(W.y);
	RND(A,B,C,D,E,F,G,H, W.x+ K[31]);
	W.y += Wr1(Z.w) + Y.z + Wr2(W.z);
	RND(H,A,B,C,D,E,F,G, W.y+ K[32]);
	W.z += Wr1(W.x) + Y.w + Wr2(W.w);
	RND(G,H,A,B,C,D,E,F, W.z+ K[33]);
	W.w += Wr1(W.y) + Z.x + Wr2(X.x);
	RND(F,G,H,A,B,C,D,E, W.w+ K[34]);

	X.x += Wr1(W.z) + Z.y + Wr2(X.y);
	RND(E,F,G,H,A,B,C,D, X.x+ K[35]);
	X.y += Wr1(W.w) + Z.z + Wr2(X.z);
	RND(D,E,F,G,H,A,B,C, X.y+ K[36]);
	X.z += Wr1(X.x) + Z.w + Wr2(X.w);
	RND(C,D,E,F,G,H,A,B, X.z+ K[37]);
	X.w += Wr1(X.y) + W.x + Wr2(Y.x);
	RND(B,C,D,E,F,G,H,A, X.w+ K[38]);

	Y.x += Wr1(X.z) + W.y + Wr2(Y.y);
	RND(A,B,C,D,E,F,G,H, Y.x+ K[39]);
	Y.y += Wr1(X.w) + W.z + Wr2(Y.z);
	RND(H,A,B,C,D,E,F,G, Y.y+ K[40]);
	Y.z += Wr1(Y.x) + W.w + Wr2(Y.w);
	RND(G,H,A,B,C,D,E,F, Y.z+ K[41]);
	Y.w += Wr1(Y.y) + X.x + Wr2(Z.x);
	RND(F,G,H,A,B,C,D,E, Y.w+ K[42]);

	Z.x += Wr1(Y.z) + X.y + Wr2(Z.y);
	RND(E,F,G,H,A,B,C,D, Z.x+ K[43]);
	Z.y += Wr1(Y.w) + X.z + Wr2(Z.z);
	RND(D,E,F,G,H,A,B,C, Z.y+ K[44]);
	Z.z += Wr1(Z.x) + X.w + Wr2(Z.w);
	RND(C,D,E,F,G,H,A,B, Z.z+ K[45]);
	Z.w += Wr1(Z.y) + Y.x + Wr2(W.x);
	RND(B,C,D,E,F,G,H,A, Z.w+ K[46]);

	W.x += Wr1(Z.z) + Y.y + Wr2(W.y);
	RND(A,B,C,D,E,F,G,H, W.x+ K[47]);
	W.y += Wr1(Z.w) + Y.z + Wr2(W.z);
	RND(H,A,B,C,D,E,F,G, W.y+ K[48]);
	W.z += Wr1(W.x) + Y.w + Wr2(W.w);
	RND(G,H,A,B,C,D,E,F, W.z+ K[49]);
	W.w += Wr1(W.y) + Z.x + Wr2(X.x);
	RND(F,G,H,A,B,C,D,E, W.w+ K[50]);

	X.x += Wr1(W.z) + Z.y + Wr2(X.y);
	RND(E,F,G,H,A,B,C,D, X.x+ K[51]);
	X.y += Wr1(W.w) + Z.z + Wr2(X.z);
	RND(D,E,F,G,H,A,B,C, X.y+ K[52]);
	X.z += Wr1(X.x) + Z.w + Wr2(X.w);
	RND(C,D,E,F,G,H,A,B, X.z+ K[53]);
	X.w += Wr1(X.y) + W.x + Wr2(Y.x);
	RND(B,C,D,E,F,G,H,A, X.w+ K[54]);

	Y.x += Wr1(X.z) + W.y + Wr2(Y.y);
	RND(A,B,C,D,E,F,G,H, Y.x+ K[55]);
	Y.y += Wr1(X.w) + W.z + Wr2(Y.z);
	RND(H,A,B,C,D,E,F,G, Y.y+ K[56]);
	Y.z += Wr1(Y.x) + W.w + Wr2(Y.w);
	RND(G,H,A,B,C,D,E,F, Y.z+ K[57]);
	Y.w += Wr1(Y.y) + X.x + Wr2(Z.x);
	RND(F,G,H,A,B,C,D,E, Y.w+ K[58]);

	Z.x += Wr1(Y.z) + X.y + Wr2(Z.y);
	RND(E,F,G,H,A,B,C,D, Z.x+ K[59]);
	Z.y += Wr1(Y.w) + X.z + Wr2(Z.z);
	RND(D,E,F,G,H,A,B,C, Z.y+ K[60]);
	Z.z += Wr1(Z.x) + X.w + Wr2(Z.w);
	RND(C,D,E,F,G,H,A,B, Z.z+ K[61]);
	Z.w += Wr1(Z.y) + Y.x + Wr2(W.x);
	RND(B,C,D,E,F,G,H,A, Z.w+ K[62]);
	
#undef A
#undef B
#undef C
#undef D
#undef E
#undef F
#undef G
#undef H

	if(notfresh){
		*state0 += S0;
		*state1 += S1;
	}else{
		S0 += (uint4)(K[73], K[77], K[78], K[79]);
		S1 += (uint4)(K[66], K[67], K[80], K[81]);
		*state0 = S0;
		*state1 = S1;
	}
}

void halfsalsa(uint4 w[4])
{
	for(uint i=0; i<4; ++i){
		w[0] ^= rotl(w[3]     +w[2]     , 7U);
		w[1] ^= rotl(w[0]     +w[3]     , 9U);
		w[2] ^= rotl(w[1]     +w[0]     ,13U);
		w[3] ^= rotl(w[2]     +w[1]     ,18U);
		w[2] ^= rotl(w[3].wxyz+w[0].zwxy, 7U);
		w[1] ^= rotl(w[2].wxyz+w[3].zwxy, 9U);
		w[0] ^= rotl(w[1].wxyz+w[2].zwxy,13U);
		w[3] ^= rotl(w[0].wxyz+w[1].zwxy,18U);
	}
}

#if (LOOKUP_GAP == 2)
void salsa(uint4 B[8], bool db){
#else
void salsa(uint4 B[8]){
#endif
    uint4 w[4];

	for(uint i=0; i<4; ++i)
		w[i] = (B[i]^=B[i+4]);
	halfsalsa(w);
	for(uint i=0; i<4; ++i)
		w[i] = (B[i+4]^=(B[i]+=w[i]));
	halfsalsa(w);
#if (LOOKUP_GAP == 2)
	if(db){
		for(uint i=0; i<4; ++i)
			w[i] = (B[i]^=(B[i+4]+=w[i]));
		halfsalsa(w);
		for(uint i=0; i<4; ++i)
			w[i] = (B[i+4]^=(B[i]+=w[i]));
		halfsalsa(w);
	}
#endif
	for(uint i=0; i<4; ++i)
		B[i+4] += w[i];
}

#define Coord(x,y,z) x+y*(x ## SIZE)+z*(y ## SIZE)*(x ## SIZE)
#define CO Coord(z,x,y)

void scrypt_core(uint4 X[8], __global uint4*restrict lookup)
{
	const uint zSIZE = 8;
	const uint ySIZE = (N[NFACTOR]/LOOKUP_GAP+(N[NFACTOR]%LOOKUP_GAP>0));
	const uint xSIZE = CONCURRENT_THREADS;
	uint x = get_global_id(0)%xSIZE;
	uint4 tmp[4];

	tmp[0] = (uint4)(X[1].x,X[2].y,X[3].z,X[0].w);
	tmp[1] = (uint4)(X[2].x,X[3].y,X[0].z,X[1].w);
	tmp[2] = (uint4)(X[3].x,X[0].y,X[1].z,X[2].w);
	tmp[3] = (uint4)(X[0].x,X[1].y,X[2].z,X[3].w);

	X[0] = EndianSwapa(tmp[0]);
	X[1] = EndianSwapb(tmp[1]);
	X[2] = EndianSwapb(tmp[2]);
	X[3] = EndianSwapb(tmp[3]);

	tmp[0] = (uint4)(X[5].x,X[6].y,X[7].z,X[4].w);
	tmp[1] = (uint4)(X[6].x,X[7].y,X[4].z,X[5].w);
	tmp[2] = (uint4)(X[7].x,X[4].y,X[5].z,X[6].w);
	tmp[3] = (uint4)(X[4].x,X[5].y,X[6].z,X[7].w);

	X[4] = EndianSwapa(tmp[0]);
	X[5] = EndianSwapb(tmp[1]);
	X[6] = EndianSwapb(tmp[2]);
	X[7] = EndianSwapb(tmp[3]);

	for(uint y=0; y<(N[NFACTOR]/LOOKUP_GAP); ++y)
	{

		for(uint z=0; z<zSIZE; ++z)
			lookup[CO] = X[z];

#if (LOOKUP_GAP == 2)
		salsa(X, 1);
#elif (LOOKUP_GAP == 1)
		salsa(X);
#else
		for(uint i=0; i<LOOKUP_GAP; ++i)
			salsa(X);
#endif
	}
#if (LOOKUP_GAP != 1) && (LOOKUP_GAP != 2) && (LOOKUP_GAP != 4) && (LOOKUP_GAP != 8)
    {
        uint y = (N[NFACTOR]/LOOKUP_GAP);
        for(uint z=0; z<zSIZE; ++z)
            lookup[CO] = X[z];
        for(uint i=0; i<N[NFACTOR]%LOOKUP_GAP; ++i)
            salsa(X);
    }
#endif

#if (LOOKUP_GAP != 1)
    for (uint i=0; i<N[NFACTOR]; ++i)
    {
        uint j = X[7].x & (N[NFACTOR]-1);
#else
	for (uint i=0; i<N[NFACTOR]; ++i){
		uint y = X[7].x & (N[NFACTOR]-1);
#endif

#if (LOOKUP_GAP == 1)
		
#elif (LOOKUP_GAP == 2)
		uint y = (j>>1);
#elif (LOOKUP_GAP == 4)
		uint y = (j>>2);
#elif (LOOKUP_GAP == 8)
		uint y = (j>>3);
#else
		uint y = (j/LOOKUP_GAP);
#endif

#if (LOOKUP_GAP != 2) && (LOOKUP_GAP != 1)
		uint4 V[8];
		for(uint z=0; z<zSIZE; ++z)
			V[z] = lookup[CO];
#endif

#if (LOOKUP_GAP == 1)
		for(uint z=0; z<zSIZE; ++z)
			X[z] ^= lookup[CO];
#elif (LOOKUP_GAP == 2)
		if(j&1){
			uint4 V[8];
			for(uint z=0; z<zSIZE; ++z)
				V[z] = lookup[CO];
			salsa(V, 0);
			for(uint z=0; z<zSIZE; ++z)
				X[z] ^= V[z];
		}else{
			for(uint z=0; z<zSIZE; ++z)
				X[z] ^= lookup[CO];
		}
#else
		uint val = j%LOOKUP_GAP;
		for (uint z=0; z<val; ++z)
			salsa(V);
#endif

#if (LOOKUP_GAP != 2) && (LOOKUP_GAP != 1)
		for(uint z=0; z<zSIZE; ++z)
			X[z] ^= V[z];
#endif

#if (LOOKUP_GAP == 2)
        salsa(X, 0);
#else
        salsa(X);
#endif
    }

	tmp[0] = (uint4)(X[3].x,X[2].y,X[1].z,X[0].w);
	tmp[1] = (uint4)(X[0].x,X[3].y,X[2].z,X[1].w);
	tmp[2] = (uint4)(X[1].x,X[0].y,X[3].z,X[2].w);
	tmp[3] = (uint4)(X[2].x,X[1].y,X[0].z,X[3].w);

	X[0] = EndianSwapa(tmp[0]);
	X[1] = EndianSwapb(tmp[1]);
	X[2] = EndianSwapb(tmp[2]);
	X[3] = EndianSwapb(tmp[3]);

	tmp[0] = (uint4)(X[7].x,X[6].y,X[5].z,X[4].w);
	tmp[1] = (uint4)(X[4].x,X[7].y,X[6].z,X[5].w);
	tmp[2] = (uint4)(X[5].x,X[4].y,X[7].z,X[6].w);
	tmp[3] = (uint4)(X[6].x,X[5].y,X[4].z,X[7].w);

	X[4] = EndianSwapa(tmp[0]);
	X[5] = EndianSwapb(tmp[1]);
	X[6] = EndianSwapb(tmp[2]);
	X[7] = EndianSwapb(tmp[3]);
}

__constant uint fixedWa[8] = {0x428a2f99,0xd807aa98,0xf59b89c2,0xb707775c,0xad87a3ea,0xc91b1417,0xe64fb6a2,0xe0a1adbe};
__constant uint fixedWb[8] = {0xf1374491,0x12835b01,0x73924787,0x0468c23f,0xbcb1d3a3,0xc359dce1,0xe84d923a,0x7c728e11};
__constant uint fixedWc[8] = {0xb5c0fbcf,0x243185be,0x23c6886e,0xe7e72b4c,0x7b993186,0xa83253a7,0xe93a5730,0x511c78e4};
__constant uint fixedWd[8] = {0xe9b5dba5,0x550c7dc3,0xa42ca65c,0x49e1f1a2,0x562b9420,0x3b13c12d,0x09837686,0x315b45bd};
__constant uint fixedWe[8] = {0x3956c25b,0x72be5d74,0x15ed3627,0x4b99c816,0xbff3ca0c,0x9d3d725d,0x078ff753,0xfca71413};
__constant uint fixedWf[8] = {0x59f111f1,0x80deb1fe,0x4d6edcbf,0x926d1570,0xda4b0c23,0xd9031a84,0x29833341,0xea28f96a};
__constant uint fixedWg[8] = {0x923f82a4,0x9bdc06a7,0xe28217fc,0xaa0fc072,0x6cd8711a,0xb1a03340,0xd5de0b7e,0x79703128};
__constant uint fixedWh[8] = {0xab1c5ed5,0xc19bf794,0xef02488f,0xadb36e2c,0x8f337caa,0x16f58012,0x6948ccf4,0x4e1ef848};

#define FOUND (0xFF)
#define SETFOUND(Xnonce) output[output[FOUND]++] = Xnonce

__attribute__((reqd_work_group_size(WORKSIZE, 1, 1)))
__kernel void search(__global const uint4 * restrict input,
volatile __global uint*restrict output, __global uint4*restrict padcache,
const uint4 midstate0, const uint4 midstate16, const uint target)
{
	uint gid = get_global_id(0);
	uint4 X[8];
	uint4 tstate0, tstate1, ostate0, ostate1, tmp0, tmp1;
	uint4 data = (uint4)(input[4].x,input[4].y,input[4].z,gid);
	uint4 pad0 = midstate0, pad1 = midstate16;

	SHA256(&pad0,&pad1, data, (uint4)(K[84],0,0,0), (uint4)(0,0,0,0), (uint4)(0,0,0, K[85]), 1);
	SHA256(&ostate0,&ostate1, pad0^ K[82], pad1^ K[82], K[82], K[82], 0);
	SHA256(&tstate0,&tstate1, pad0^ K[83], pad1^ K[83], K[83], K[83], 0);

	tmp0 = tstate0;
	tmp1 = tstate1;
	SHA256(&tstate0, &tstate1, input[0],input[1],input[2],input[3], 1);

	for (uint i=0; i<4; i++)
	{
		pad0 = tstate0;
		pad1 = tstate1;
		X[(i<<1) ] = ostate0;
		X[(i<<1)+1] = ostate1;

		SHA256(&pad0, &pad1, data, (uint4)(i+1,K[84],0,0), (uint4)(0,0,0,0), (uint4)(0,0,0, K[86]), 1);
		SHA256(X+(i<<1),X+(i<<1)+1, pad0, pad1, (uint4)(K[84], 0U, 0U, 0U), (uint4)(0U, 0U, 0U, K[87]), 1);
	}

	scrypt_core(X,padcache);

	SHA256(&tmp0,&tmp1, X[0], X[1], X[2], X[3], 1);
	SHA256(&tmp0,&tmp1, X[4], X[5], X[6], X[7], 1);

	tstate0 = tmp0;
	tstate1 = tmp1;
#define A tstate0.x
#define B tstate0.y
#define C tstate0.z
#define D tstate0.w
#define E tstate1.x
#define F tstate1.y
#define G tstate1.z
#define H tstate1.w

	for(uint i=0; i<8; i++){
		RND(A,B,C,D,E,F,G,H, fixedWa[i]);
		RND(H,A,B,C,D,E,F,G, fixedWb[i]);
		RND(G,H,A,B,C,D,E,F, fixedWc[i]);
		RND(F,G,H,A,B,C,D,E, fixedWd[i]);
		RND(E,F,G,H,A,B,C,D, fixedWe[i]);
		RND(D,E,F,G,H,A,B,C, fixedWf[i]);
		RND(C,D,E,F,G,H,A,B, fixedWg[i]);
		RND(B,C,D,E,F,G,H,A, fixedWh[i]);
	}

#undef A
#undef B
#undef C
#undef D
#undef E
#undef F
#undef G
#undef H
	tmp0 += tstate0;
	tmp1 += tstate1;

	SHA256(&ostate0,&ostate1, tmp0, tmp1, (uint4)(K[84], 0U, 0U, 0U), (uint4)(0U, 0U, 0U, K[87]), 1);

	bool result = (EndianSwapa(ostate1.w) <= target);
	if (result)
		SETFOUND(gid);
}
