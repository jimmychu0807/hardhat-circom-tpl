pragma circom 2.1.6;

include "circomlib/poseidon.circom";
// include "https://github.com/0xPARC/circom-secp256k1/blob/master/circuits/bigint.circom";

template Num2Bits(nBits) {
  signal input in;
  signal output out[nBits];

  var accum = 0;
  for (var i = 0; i < nBits; i++) {
    out[i] <-- (in >> i) & 1;
    out[i] * (out[i] - 1) === 0;
    accum += out[i] * (2 ** i);
  }

  accum === in;
}

template IsZero() {
  signal input in;
  signal output out;

  signal inv <-- in == 0 ? 1 : 1/in;
  out <== 1 - in * inv;
  in * out === 0;
}

template IsEqual() {
  signal input in[2];
  signal output out;

  component isz = IsZero();
  isz.in <== in[0] - in[1];
  out <== isz.out;
}

template LessThan(n) {
  assert(n <= 252);
  signal input in[2];
  signal output out;

  component n2b = Num2Bits(n+1);
  n2b.in <== in[0] + (1 << n) - in[1];
  out <== 1 - n2b.out[n];
}

template LessThanEq(n) {
  signal input in[2];
  signal output out;

  component lt = LessThan(n);
  lt.in <== [in[0], in[1] + 1];
  out <== lt.out;
}

template Selector(nChoices) {
  // check that the index is constrainted accordingly
  // check that the out is constranted to in[index]

  signal input in[nChoices];
  signal input index;
  signal output out;

  // check that the index is constrainted accordingly
  component lt = LessThan(4);
  lt.in <== [index, nChoices];

  var idx = lt.out == 1 ? index : 0;
  out <-- in[idx];
}

template SecretToPublic () {
  signal input sk;
  signal output pk;

  component poseidon = Poseidon(1);
  poseidon.inputs[0] <== sk;
  pk <== poseidon.out;

  log("poseidon pk:", pk);
}

template Sign() {
  signal input m;
  signal input sk; // private
  signal input pk;

  // check that we know the secret key corresponding to the public key
  component checker = SecretToPublic();
  checker.sk <== sk;
  pk === checker.pk;

  // dummy constraint
  signal mSquared <== m * m;
}

template GroupSignVerifier(n) {
  signal input m;
  signal input sk; // private
  signal input pk[n];

  component checker = SecretToPublic();
  checker.sk <== sk;

  signal zeroChecker[n+1];
  zeroChecker[0] <== 1;
  for (var i = 0; i < n; i++) {
      zeroChecker[i+1] <== zeroChecker[i] * (pk[i] - checker.pk);
  }
  zeroChecker[n] === 0;

  // dummy constraint
  signal mSquared <== m * m;
}

template DualMux() {
  signal input index;
  signal input in[2];
  signal output out[2];

  0 === index * (1 - index);
  // out[0] <== index * in[1] + (1 - index) * in[0];
  out[0] <== index * (in[1] - in[0]) + in[0];
  // out[1] <== (1 - index) * in[1] + index * in[0];
  out[1] <== index * (in[0] - in[1]) + in[1];
}

template MerkleTreeMembership(nLevels) {
  signal input sk;
  signal input root;
  signal input siblings[nLevels];
  signal input pathIndices[nLevels]; // 0 if left sibling, 1 if right sibling

  component checker = SecretToPublic();
  checker.sk <== sk;

  signal intermediateHash[nLevels + 1];
  intermediateHash[0] <== checker.pk;

  component poseidons[nLevels];
  component muxes[nLevels];

  for (var i = 0; i < nLevels; i++) {
    muxes[i] = DualMux();
    muxes[i].index <== pathIndices[i];
    muxes[i].in <== [intermediateHash[i], siblings[i]];

    poseidons[i] = Poseidon(2);
    poseidons[i].inputs <== muxes[i].out;
    intermediateHash[i + 1] <== poseidons[i].out;
  }

  root === intermediateHash[nLevels];
}

component main { public [root] } = MerkleTreeMembership(15);
