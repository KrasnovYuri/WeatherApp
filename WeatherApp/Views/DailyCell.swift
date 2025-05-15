//
//  DailyCell.swift
//  WeatherApp
//
//  Created by Юрий on 14.05.2025.
//

import UIKit
import Kingfisher

// MARK: - Ячейка для ежедневного прогноза
final class DailyCell: UITableViewCell {
    let dayLabel = UILabel()
    private let iconImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(iconImageView)
        addSubview(dayLabel)
        
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        backgroundColor = .clear
        
        NSLayoutConstraint.activate([
            dayLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dayLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 130),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
        ])
    }
    
    func configure(dayText: String, iconURL: URL?) {
        dayLabel.text = dayText
        if let url = iconURL {
            iconImageView.kf.setImage(with: url)
        } else {
            iconImageView.image = nil
        }
    }
}
