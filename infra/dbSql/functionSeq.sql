DELIMITER //

CREATE FUNCTION get_next_sequence(seq_name VARCHAR(50)) RETURNS INT
BEGIN
    DECLARE next_val INT;
    
    -- 指定されたシーケンス名の現在の値を取得
    SELECT current_value INTO next_val
    FROM sequence_table
    WHERE sequence_name = seq_name
    FOR UPDATE;
    
    -- 値を1増やして更新
    UPDATE sequence_table
    SET current_value = next_val + 1
    WHERE sequence_name = seq_name;
    
    -- 更新前の値（次のシーケンス値）を返す
    RETURN next_val;
END //

DELIMITER ;
