export function traceTime(name) {
    return function(f) {
        const start = new Date()
        const res = f()
        const end = new Date()
        console.log(name + " took " + (end - start) + "ms")
        return res
    }
}
  