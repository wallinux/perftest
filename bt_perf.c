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

/* Obtain a backtrace and print it to stdout. */
void NOINLINE print_trace (void)
{
	void *array[10];
	size_t size;
	char **strings;
	size_t i;

	size = backtrace(array, 10);
	strings = backtrace_symbols(array, size);

	printf ("Obtained %zd stack frames.\n", size);

	for (i = 0; i < size; i++)
		printf ("%s\n", strings[i]);

	free (strings);
	if (stop == 1) {
		sleep(2);
		exit(1);
	}
}

int NOINLINE perf_e(int i)
{
	static int once = 1;
	printf ("    %s: %i\n", __func__, i);
	if (once) {
		print_trace();
		once=0;
		sleep(1);
	}
	return i + once;
}

int NOINLINE perf_d(int i)
{
	printf ("   %s: %i\n", __func__, i);
	return perf_e(i*2);
}

void NOINLINE perf_c(int i)
{
	static int j;

	printf ("  %s: %i\n", __func__, i);
	j += perf_d(i*2);
}

void NOINLINE perf_b(int i)
{
	printf (" %s: %i\n", __func__, i);
	perf_c(i*2);
}

void NOINLINE perf_a(char str[])
{
	int i = 1;

	printf ("%s: %s\n", __func__, str);
	while (1) {
		perf_b(i);
		i++;
		printf("\n");
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
