/**
 * @file stl_suite.cpp
 * @brief C++20 STL header and explicit template instantiation benchmark workload (Experiment 1).
 */

#include <algorithm>
#include <coroutine>
#include <cstdint>
#include <map>
#include <string>
#include <vector>

template class std::vector<int>;
template class std::vector<std::uint64_t>;
template class std::vector<std::string>;
template class std::map<int, std::string>;
template class std::basic_string<char>;

struct MinimalTask {
  struct promise_type {
    MinimalTask get_return_object() noexcept { return {}; }
    std::suspend_never initial_suspend() noexcept { return {}; }
    std::suspend_never final_suspend() noexcept { return {}; }
    void return_void() noexcept {}
    void unhandled_exception() noexcept {}
  };
};

static MinimalTask run_minimal_coro(std::vector<int> &v) {
  std::sort(v.begin(), v.end());
  co_return;
}

int main(int argc, char **argv) {
  (void)argv;
  std::vector<int> vals = {9, 4, 7, 1, argc};
  std::map<int, std::string> labels;
  labels[vals[0]] = "edgcpp";
  run_minimal_coro(vals);
  return (vals[0] <= vals[4] && !labels.empty()) ? 0 : 1;
}
