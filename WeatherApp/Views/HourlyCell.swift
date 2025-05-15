//
//  HourlyCell.swift
//  WeatherApp
//
//  Created by Юрий on 14.05.2025.
//

import UIKit
import Kingfisher

// MARK: - Ячейка для почасового прогноза
final class HourlyCell: UICollectionViewCell {
    private let hourLabel = UILabel()
    private let tempLabel = UILabel()
    private let iconImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [hourLabel, tempLabel, iconImageView])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4
        
        hourLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        tempLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        iconImageView.contentMode = .scaleAspectFit
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func configure(hour: String, temp: String, iconURL: URL?) {
        hourLabel.text = hour
        tempLabel.text = temp
        
        if let url = iconURL {
            iconImageView.kf.setImage(with: url)
        } else {
            iconImageView.image = nil // или placeholder
        }
    }
}
