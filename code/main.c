#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>

void delete_ambiguous(char x[], char y[]) {
    int index = 0;
    char z[128] = {0};
    for (int i = 0; i < strlen(x); i++) {
        int skip = 0;
        for (int j = 0; j < strlen(y); j++) {
            if (x[i] == y[j]) {
                skip = 1;
                break;
            }
        }
        if (skip == 0) {
            z[index] = x[i];
            index++;
        }
    }
    strcpy(x, z);
}

void print_help(char* program_name) {
    printf("Usage: %s [-l length] [-a] [-s] [-h]\n", program_name);
    printf("Options:\n");
    printf("  -l length  Set the length of the password (default: 16)\n");
    printf("  -a         Include ambiguous characters (default: exclude)\n");
    printf("  -s         Include at least one symbol and one uppercase character (default: exclude)\n");
    printf("  -h         Display this help message\n");
}

int is_all_digits(char *str) {
    int i = 0;
    while (str[i]) {
        if (!isdigit(str[i])) {
            return 0;
        }
        i++;
    }
    return 1;
}

int main(int argc, char* argv[]) {
    int length = 16;
    int exclude_ambiguous = 1;
    int force_complexity = 0;

    // Parse command line arguments
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-l") == 0) {
            if (i + 1 < argc && is_all_digits(argv[i+1])) {
                length = atoi(argv[i+1]);
                i++;
            } else {
                fprintf(stderr, "Error: -l option requires a number argument\n");
                return 1;
            }
        } else if (strcmp(argv[i], "-a") == 0) {
            exclude_ambiguous = 0;
        } else if (strcmp(argv[i], "-s") == 0) {
            force_complexity = 1;
        } else if (strcmp(argv[i], "-h") == 0) {
            print_help(argv[0]);
            return 0;
        } else {
            fprintf(stderr, "Error: unknown option '%s'\n", argv[i]);
            return 1;
        }
    }

    // Define character sets
    char digits[] = "0123456789";
    char lowercase[] = "abcdefghijklmnopqrstuvwxyz";
    char uppercase[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    char symbols[] = "!#$%";
    // char symbols[] = "!@#$%^&*()-_=+";

    char ambiguous[] = "iloIO01";

    if (exclude_ambiguous) {
        delete_ambiguous(digits, ambiguous);
        delete_ambiguous(lowercase, ambiguous);
        delete_ambiguous(uppercase, ambiguous);
    }

    char charset[128] = {0};
    strcpy(charset, digits);
    strcat(charset, lowercase);
    strcat(charset, uppercase);
    strcat(charset, symbols);

    // Seed random number generator
    struct timeval tv;
    gettimeofday(&tv, NULL);
    srand(tv.tv_usec);

    // Generate password
    char password[length];
    for (int i = 0; i < length; i++) {
        password[i] = charset[rand() % strlen(charset)];
    }

    int n = 3;
    if (force_complexity && length > n-1) {
        int nums[n];
        while (1) {
            for (int i = 0; i < n; i++) {
                nums[i] = rand() % length;
            }
            if (nums[0] != nums[1] && nums[0] != nums[2] && nums[1] != nums[2]){
                break;
            }
        }
        password[nums[0]] = digits[rand() % strlen(digits)];
        password[nums[1]] = uppercase[rand() % strlen(uppercase)];
        password[nums[2]] = symbols[rand() % strlen(symbols)];
    }

    password[length] = '\0';

    printf("%s\n", password);
    return 0;
}