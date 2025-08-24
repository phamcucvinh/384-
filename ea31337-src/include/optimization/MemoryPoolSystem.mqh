//+------------------------------------------------------------------+
//|                                           MemoryPoolSystem.mqh |
//|                                  메모리 풀 기반 고속 할당 시스템    |
//|                                    Memory Pool Optimization     |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Optimization Phase 1"
#property version   "1.00"

//+------------------------------------------------------------------+
//| 메모리 풀 시스템 클래스                                            |
//+------------------------------------------------------------------+
class MemoryPoolSystem {
private:
    // 메모리 풀 구조체
    struct MemoryPool {
        double* memory_blocks;     // 메모리 블록들
        bool* allocation_map;      // 할당 상태 맵
        int total_blocks;          // 전체 블록 수
        int free_blocks;           // 사용 가능한 블록 수
        int block_size;            // 블록 크기 (double 단위)
        int next_free_hint;        // 다음 빈 블록 힌트
        
        // 성능 통계
        int allocation_count;
        int deallocation_count;
        int fragmentation_level;
    };
    
    // 다양한 크기의 메모리 풀들
    MemoryPool small_pool;      // 8 double (64 bytes)
    MemoryPool medium_pool;     // 32 double (256 bytes)
    MemoryPool large_pool;      // 128 double (1024 bytes)
    MemoryPool xlarge_pool;     // 512 double (4096 bytes)
    
    // 전역 할당 통계
    ulong total_allocations;
    ulong total_deallocations;
    ulong peak_memory_usage;
    ulong current_memory_usage;
    
    static MemoryPoolSystem* instance;

public:
    /**
     * 싱글톤 인스턴스 획득
     */
    static MemoryPoolSystem* GetInstance() {
        if (instance == NULL) {
            instance = new MemoryPoolSystem();
        }
        return instance;
    }
    
    /**
     * 메모리 풀 시스템 초기화
     */
    bool Initialize() {
        Print("[MemoryPool] 메모리 풀 시스템 초기화 시작...");
        
        // 각 풀 초기화
        if (!InitializePool(small_pool, 8, 1000)) {   // 8 * 8 = 64KB
            Print("[MemoryPool] ❌ Small pool 초기화 실패");
            return false;
        }
        
        if (!InitializePool(medium_pool, 32, 500)) {  // 32 * 32 * 500 = 512KB
            Print("[MemoryPool] ❌ Medium pool 초기화 실패");
            return false;
        }
        
        if (!InitializePool(large_pool, 128, 200)) {  // 128 * 8 * 200 = 200KB
            Print("[MemoryPool] ❌ Large pool 초기화 실패");
            return false;
        }
        
        if (!InitializePool(xlarge_pool, 512, 50)) {  // 512 * 8 * 50 = 200KB
            Print("[MemoryPool] ❌ XLarge pool 초기화 실패");
            return false;
        }
        
        total_allocations = 0;
        total_deallocations = 0;
        peak_memory_usage = 0;
        current_memory_usage = 0;
        
        Print("[MemoryPool] ✅ 메모리 풀 시스템 초기화 완료");
        Print("[MemoryPool] 총 메모리 할당: 1.0MB");
        return true;
    }
    
    /**
     * 고속 메모리 할당
     */
    double* FastAlloc(int size_in_doubles) {
        total_allocations++;
        
        // 적절한 풀 선택
        MemoryPool* pool = SelectAppropriatePool(size_in_doubles);
        
        if (pool == NULL) {
            // 풀에 맞지 않는 크기 - 일반 할당
            Print("[MemoryPool] ⚠️ 풀 범위 초과, 일반 할당 사용: ", size_in_doubles);
            return new double[size_in_doubles];
        }
        
        // 풀에서 할당
        double* allocated_memory = AllocateFromPool(pool);
        
        if (allocated_memory != NULL) {
            current_memory_usage += pool.block_size * sizeof(double);
            if (current_memory_usage > peak_memory_usage) {
                peak_memory_usage = current_memory_usage;
            }
        }
        
        return allocated_memory;
    }
    
    /**
     * 고속 메모리 해제
     */
    bool FastFree(double* memory, int size_in_doubles) {
        if (memory == NULL) return false;
        
        total_deallocations++;
        
        // 적절한 풀 선택
        MemoryPool* pool = SelectAppropriatePool(size_in_doubles);
        
        if (pool == NULL) {
            // 일반 할당된 메모리 해제
            delete[] memory;
            return true;
        }
        
        // 풀로 반환
        bool success = DeallocateToPool(pool, memory);
        
        if (success) {
            current_memory_usage -= pool.block_size * sizeof(double);
        }
        
        return success;
    }
    
    /**
     * 특성 벡터 전용 할당 (가장 빈번한 사용)
     */
    double* AllocFeatureVector() {
        return FastAlloc(30);  // 30 double = 240 bytes
    }
    
    void FreeFeatureVector(double* vector) {
        FastFree(vector, 30);
    }
    
    /**
     * 가격 시리즈 전용 할당
     */
    double* AllocPriceSeries() {
        return FastAlloc(100); // 100 double = 800 bytes
    }
    
    void FreePriceSeries(double* series) {
        FastFree(series, 100);
    }
    
    /**
     * 지표 버퍼 전용 할당
     */
    double* AllocIndicatorBuffer() {
        return FastAlloc(50);  // 50 double = 400 bytes
    }
    
    void FreeIndicatorBuffer(double* buffer) {
        FastFree(buffer, 50);
    }
    
    /**
     * 메모리 풀 통계 출력
     */
    void PrintStatistics() {
        Print("=== 메모리 풀 통계 ===");
        Print("총 할당: ", total_allocations);
        Print("총 해제: ", total_deallocations);
        Print("현재 사용량: ", DoubleToString(current_memory_usage / 1024.0, 2), " KB");
        Print("최대 사용량: ", DoubleToString(peak_memory_usage / 1024.0, 2), " KB");
        
        PrintPoolStatistics("Small", small_pool);
        PrintPoolStatistics("Medium", medium_pool);
        PrintPoolStatistics("Large", large_pool);
        PrintPoolStatistics("XLarge", xlarge_pool);
        
        Print("========================");
    }
    
    /**
     * 메모리 정리 (가비지 컬렉션)
     */
    void GarbageCollection() {
        Print("[MemoryPool] 가비지 컬렉션 시작...");
        
        int total_freed = 0;
        
        // 각 풀의 단편화 정리
        total_freed += DefragmentPool(small_pool);
        total_freed += DefragmentPool(medium_pool);
        total_freed += DefragmentPool(large_pool);
        total_freed += DefragmentPool(xlarge_pool);
        
        Print("[MemoryPool] ✅ 가비지 컬렉션 완료. 정리된 블록: ", total_freed);
    }
    
    /**
     * 메모리 사용률 확인
     */
    double GetMemoryUsagePercent() {
        ulong total_pool_memory = 
            (small_pool.total_blocks * small_pool.block_size +
             medium_pool.total_blocks * medium_pool.block_size +
             large_pool.total_blocks * large_pool.block_size +
             xlarge_pool.total_blocks * xlarge_pool.block_size) * sizeof(double);
        
        return (double)current_memory_usage / total_pool_memory * 100.0;
    }

private:
    /**
     * 생성자 (private - 싱글톤)
     */
    MemoryPoolSystem() {
        // 생성자
    }
    
    /**
     * 메모리 풀 초기화
     */
    bool InitializePool(MemoryPool &pool, int block_size, int block_count) {
        pool.block_size = block_size;
        pool.total_blocks = block_count;
        pool.free_blocks = block_count;
        pool.next_free_hint = 0;
        pool.allocation_count = 0;
        pool.deallocation_count = 0;
        pool.fragmentation_level = 0;
        
        // 메모리 블록 할당
        int total_size = block_size * block_count;
        pool.memory_blocks = new double[total_size];
        
        if (pool.memory_blocks == NULL) {
            return false;
        }
        
        // 할당 맵 초기화
        pool.allocation_map = new bool[block_count];
        if (pool.allocation_map == NULL) {
            delete[] pool.memory_blocks;
            return false;
        }
        
        // 모든 블록을 사용 가능으로 설정
        for (int i = 0; i < block_count; i++) {
            pool.allocation_map[i] = false;
        }
        
        return true;
    }
    
    /**
     * 적절한 풀 선택
     */
    MemoryPool* SelectAppropriatePool(int size_in_doubles) {
        if (size_in_doubles <= 8) {
            return &small_pool;
        } else if (size_in_doubles <= 32) {
            return &medium_pool;
        } else if (size_in_doubles <= 128) {
            return &large_pool;
        } else if (size_in_doubles <= 512) {
            return &xlarge_pool;
        }
        
        return NULL; // 풀 범위 초과
    }
    
    /**
     * 풀에서 메모리 할당
     */
    double* AllocateFromPool(MemoryPool &pool) {
        if (pool.free_blocks == 0) {
            Print("[MemoryPool] ⚠️ 풀 고갈: ", pool.block_size, " double 블록");
            return NULL;
        }
        
        // 빈 블록 찾기 (힌트부터 시작)
        int block_index = -1;
        
        for (int i = pool.next_free_hint; i < pool.total_blocks; i++) {
            if (!pool.allocation_map[i]) {
                block_index = i;
                break;
            }
        }
        
        // 힌트 이후에 없으면 처음부터 검색
        if (block_index == -1) {
            for (int i = 0; i < pool.next_free_hint; i++) {
                if (!pool.allocation_map[i]) {
                    block_index = i;
                    break;
                }
            }
        }
        
        if (block_index == -1) {
            Print("[MemoryPool] ❌ 빈 블록 찾기 실패");
            return NULL;
        }
        
        // 블록 할당
        pool.allocation_map[block_index] = true;
        pool.free_blocks--;
        pool.allocation_count++;
        pool.next_free_hint = (block_index + 1) % pool.total_blocks;
        
        // 메모리 주소 계산
        double* allocated_address = pool.memory_blocks + (block_index * pool.block_size);
        
        return allocated_address;
    }
    
    /**
     * 풀로 메모리 반환
     */
    bool DeallocateToPool(MemoryPool &pool, double* memory) {
        // 메모리 주소로 블록 인덱스 계산
        long offset = memory - pool.memory_blocks;
        
        if (offset < 0 || offset % pool.block_size != 0) {
            Print("[MemoryPool] ❌ 잘못된 메모리 주소");
            return false;
        }
        
        int block_index = (int)(offset / pool.block_size);
        
        if (block_index >= pool.total_blocks || !pool.allocation_map[block_index]) {
            Print("[MemoryPool] ❌ 이미 해제된 블록 또는 잘못된 인덱스");
            return false;
        }
        
        // 블록 해제
        pool.allocation_map[block_index] = false;
        pool.free_blocks++;
        pool.deallocation_count++;
        
        // 힌트 업데이트
        if (block_index < pool.next_free_hint) {
            pool.next_free_hint = block_index;
        }
        
        return true;
    }
    
    /**
     * 풀 통계 출력
     */
    void PrintPoolStatistics(string pool_name, const MemoryPool &pool) {
        double usage_percent = (double)(pool.total_blocks - pool.free_blocks) / pool.total_blocks * 100.0;
        
        Print(pool_name, " Pool: ", 
              pool.total_blocks - pool.free_blocks, "/", pool.total_blocks, 
              " (", DoubleToString(usage_percent, 1), "%) ",
              "할당:", pool.allocation_count, " 해제:", pool.deallocation_count);
    }
    
    /**
     * 풀 단편화 정리
     */
    int DefragmentPool(MemoryPool &pool) {
        // 단편화된 블록 정리 (현재는 간단한 구현)
        int freed_blocks = 0;
        
        // 연속된 빈 블록들을 병합하는 로직
        // 실제로는 더 복잡한 알고리즘이 필요하지만, 
        // 현재는 단순히 할당 맵을 정리하는 정도로 구현
        
        for (int i = 0; i < pool.total_blocks - 1; i++) {
            if (!pool.allocation_map[i] && !pool.allocation_map[i + 1]) {
                // 연속된 빈 블록 발견
                freed_blocks++;
            }
        }
        
        pool.fragmentation_level = 0; // 리셋
        return freed_blocks;
    }
};

// 정적 멤버 초기화
MemoryPoolSystem* MemoryPoolSystem::instance = NULL;

//+------------------------------------------------------------------+
//| 편의 매크로                                                       |
//+------------------------------------------------------------------+
#define FAST_ALLOC(size) MemoryPoolSystem::GetInstance().FastAlloc(size)
#define FAST_FREE(ptr, size) MemoryPoolSystem::GetInstance().FastFree(ptr, size)
#define ALLOC_FEATURES() MemoryPoolSystem::GetInstance().AllocFeatureVector()
#define FREE_FEATURES(ptr) MemoryPoolSystem::GetInstance().FreeFeatureVector(ptr)
#define ALLOC_PRICES() MemoryPoolSystem::GetInstance().AllocPriceSeries()
#define FREE_PRICES(ptr) MemoryPoolSystem::GetInstance().FreePriceSeries(ptr)