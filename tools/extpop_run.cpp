// extpop_run: load a CEPOP v1 population and run V0 and/or V6 on it. See tools/extpop_cli.hpp and docs/synthetic_population.md.
#include "extpop_cli.hpp"

int main(int argc, char** argv) { return extpop::run_cli(argc, argv, stdout, stderr); }
