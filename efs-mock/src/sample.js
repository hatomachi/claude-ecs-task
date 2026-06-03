function add(a, b) {
    // バグ埋め込み用の適当なコード
    console.log("Adding numbers");
    return a + b
}

function divide(a, b) {
    return a / b  // ゼロ除算チェックなし
}

function getUserName(user) {
    return user.profile.name  // user や profile が null の場合に落ちる
}

const result = add("1", 2);  // 型の不一致
console.log(result);
