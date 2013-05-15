// file which tries to add compatibility with other operating
// systems (aside from Linux)

#ifdef _MSC_VER 
// code for windows
typedef __int32 int32_t;
typedef unsigned __int32 uint32_t;
#define isnan _isnan
#else
// code for Linux
#include <stdint.h>
#endif
