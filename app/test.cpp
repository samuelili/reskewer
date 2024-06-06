#include <iostream>
#include <cctype> 
#include <cassert>
#include <cstring> 
using namespace std;

const int MAX_WORD_LENGTH = 20;
const int MAX_TOOTH_LENGTH = 240;

void toLowerCase(char* str) {
    while (*str) {
        *str = tolower((unsigned char)*str);
        str++;
    }
}

bool hasOnlyLetters(const char* str) {
    while (*str) {
        if (!isalpha((unsigned char)(*str))) {
            return false;
        }
        str++;
    }
    return true;
}

bool isSameString(const char* str1, const char* str2) {
    return strcmp(str1, str2) == 0;
}

void normalize(const char* src, char* dest){
    while (*src){
        if (isalpha((unsigned char)(*src)) || *src == ' '){
            *dest++ = tolower((unsigned char)(*src));
        }
        src++;
    }
    *dest = '\0';
}

void extractWords(const char* str, char words[][MAX_WORD_LENGTH + 1], int& wordCount) {
    int charIndex = 0;
    wordCount = 0;

    while (*str) {
        if (*str == ' ') {
            if (charIndex > 0) {
                words[wordCount][charIndex] = '\0';
                wordCount++;
                charIndex = 0;
            }
        } else {
            words[wordCount][charIndex++] = *str;
        }
        str++;
    }
    if (charIndex > 0) {
        words[wordCount][charIndex] = '\0';
        wordCount++;
    }
}


bool isMatch(const char* wordin, const char* wordout, const char words[][MAX_WORD_LENGTH + 1], int wordCount) {
    bool sawWordIn = false;
    for (int i = 0; i < wordCount; i++) {
        if (isSameString(wordin, words[i])) {
            sawWordIn = true;
            if (wordout[0] == '\0') {
                return true;
            }
            for (int j = 0; j < wordCount; j++) {
                if (isSameString(wordout, words[j])) {
                    return false;
                }
            }
        }
    }
    return sawWordIn;
}


int normalizeCriteria(char wordin[][MAX_WORD_LENGTH + 1], char wordout[][MAX_WORD_LENGTH + 1], int nCriteria) {
    if (nCriteria < 0) {
        nCriteria = 0; // Treat negative nCriteria as 0
    }

    int validCount = 0;

    for (int i = 0; i < nCriteria; i++) {
        toLowerCase(wordin[i]);
        toLowerCase(wordout[i]);

        if (wordin[i][0] == '\0' || !hasOnlyLetters(wordin[i]) || !hasOnlyLetters(wordout[i])) {
            continue;
        }
        if (isSameString(wordin[i], wordout[i])) {
            continue;
        }

        // Check for duplicates, prioritize one-word criteria
        bool isDuplicate = false;
        for (int j = 0; j < validCount; j++) {
            if (isSameString(wordin[i], wordin[j])) {
                if (wordout[i][0] == '\0' && wordout[j][0] != '\0') {
                    // If current is one-word and the existing is two-word, replace it
                    strncpy(wordin[j], wordin[i], MAX_WORD_LENGTH + 1);
                    strncpy(wordout[j], wordout[i], MAX_WORD_LENGTH + 1);
                    isDuplicate = true;
                    break;
                } else if (wordout[j][0] == '\0' || isSameString(wordout[i], wordout[j])) {
                    // If both are two-word and match, mark as duplicate
                    isDuplicate = true;
                    break;
                }
            }
        }
        if (!isDuplicate) {
            // Move the valid criterion to the next position
            if (validCount != i) {
                strncpy(wordin[validCount], wordin[i], MAX_WORD_LENGTH + 1);
                strncpy(wordout[validCount], wordout[i], MAX_WORD_LENGTH + 1);
            }
            validCount++;
        }
    }

    // Ensure one-word criteria are prioritized and duplicates are removed
    for (int i = 0; i < validCount; i++) {
        if (wordout[i][0] == '\0') {
            for (int j = i + 1; j < validCount; j++) {
                if (isSameString(wordin[i], wordin[j])) {
                    // Remove duplicate entries
                    for (int k = j; k < validCount - 1; k++) {
                        strncpy(wordin[k], wordin[k + 1], MAX_WORD_LENGTH + 1);
                        strncpy(wordout[k], wordout[k + 1], MAX_WORD_LENGTH + 1);
                    }
                    validCount--;
                    j--; // Decrement j to check the next element after shifting
                }
            }
        }
    }

    // Final pass to remove exact duplicates
    for (int i = 0; i < validCount; i++) {
        for (int j = i + 1; j < validCount; j++) {
            if (isSameString(wordin[i], wordin[j]) && isSameString(wordout[i], wordout[j])) {
                // Remove the duplicate by shifting left
                for (int k = j; k < validCount - 1; k++) {
                    strncpy(wordin[k], wordin[k + 1], MAX_WORD_LENGTH + 1);
                    strncpy(wordout[k], wordout[k + 1], MAX_WORD_LENGTH + 1);
                }
                validCount--;
                j--; // Decrement j to check the next element after shifting
            }
        }
    }

    return validCount;
}

int computeScore(const char wordin[][MAX_WORD_LENGTH+1],const char wordout[][MAX_WORD_LENGTH+1],int nCriteria,const char tooth[]){
    if (nCriteria < 0) {
        nCriteria = 0; // Treat negative nCriteria as 0
    }

    char normalizedTooth[MAX_TOOTH_LENGTH + 1];
    normalize(tooth, normalizedTooth);

    char words[MAX_TOOTH_LENGTH / 2][MAX_WORD_LENGTH + 1];
    int wordCount = 0;
    extractWords(normalizedTooth, words, wordCount);

    int score = 0;
    for (int i = 0; i < nCriteria; i++) {
        if (isMatch(wordin[i], wordout[i], words, wordCount)) {
            score++;
        }
    }

    return score;
                 
}

 int main()
        {
            const int TEST1_NCRITERIA = 3;
            char test1win[TEST1_NCRITERIA][MAX_WORD_LENGTH+1] = {
                "floss", "brush", "hair"
            };
            char test1wout[TEST1_NCRITERIA][MAX_WORD_LENGTH+1] = {
                "",      "hair", ""
            };
            assert(computeScore(test1win, test1wout, TEST1_NCRITERIA,
                     "Be sure to brush your teeth and to floss thoroughly.") == 2);
            assert(computeScore(test1win, test1wout, TEST1_NCRITERIA,
                     "Be sure to brush your hair before showering if it's long.") == 1);
            assert(computeScore(test1win, test1wout, TEST1_NCRITERIA-1,  // notice the -1
                     "Be sure to brush your hair before showering if it's long.") == 0);
            assert(computeScore(test1win, test1wout, TEST1_NCRITERIA,
                     "At the hair salon, should I go for short hair or long hair?") == 1);
            assert(computeScore(test1win, test1wout, TEST1_NCRITERIA,
                     "hair&nail salon") == 0);
            assert(computeScore(test1win, test1wout, TEST1_NCRITERIA,
                     "**** 2024 ****") == 0);
            cout << "All tests succeeded" << endl;
        }
