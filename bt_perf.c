#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <time.h>

int stop = 0;

#define NOINLINE __attribute__ ((noinline))
#define ARM __attribute__(("arm"))
#define THUMB __attribute__(("thumb"))


#ifdef DEBUG
#warning "Building with trace messages"
#define TRACE(fmt, ...) \
       do { printf(fmt, __VA_ARGS__); } while (0)
#else
#define TRACE(fmt, ...) {}
#endif


#define MAX_PRIME 50000

void NOINLINE do_primes(void)
{
    unsigned long i, num, primes = 0;
    for (num = 1; num <= MAX_PRIME; ++num) {
        for (i = 2; (i <= num) && (num % i != 0); ++i);
        if (i == num)
            ++primes;
    }
    TRACE("Calculated %li primes.\n", primes);
}


/* Obtain a backtrace and print it to stdout. */
void NOINLINE print_trace(void)
{
	void *array[10];
	size_t size;
	char **strings;
	size_t i;

	size = backtrace(array, 10);
	strings = backtrace_symbols(array, size);

	TRACE("Obtained %zd stack frames.\n", size);

	for (i = 0; i < size; i++)
		TRACE("%s\n", strings[i]);

	free (strings);
	if (stop == 1) {
		/* burning time */
		do_primes();
		exit(1);
	}
}

int NOINLINE perf_e(int i)
{
	static int once = 1;
	TRACE("    %s: %i\n", __func__, i);
	if (once) {
		print_trace();
		once=0;
		sleep(1);
	}
	return i + once;
}

int NOINLINE perf_d(int i)
{
	TRACE("   %s: %i\n", __func__, i);
	return perf_e(i*2);
}

void NOINLINE perf_c(int i)
{
	static int j;

	TRACE("  %s: %i\n", __func__, i);
	j += perf_d(i*2);
}

void NOINLINE perf_b(int i)
{
	TRACE(" %s: %i\n", __func__, i);
	perf_c(i*2);
}

void NOINLINE perf_a(char str[])
{
	int i = 1;

	TRACE("%s: %s\n", __func__, str);
	while (1) {
		perf_b(i);
		i++;
		TRACE("%s","\n");
	}
}

int main(int argc, char **argv)
{
	if (argc > 1 ) {
		stop = 1;
		perf_a(argv[1]);
	}
	else
		perf_a("noarg");

	return 0;
}
